import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Plaintext JSON schema for the sensitive fields of a Medication, before
/// envelope encryption.
///
/// Mirrors the contract in `EncryptedPersonPayload`: this is the shape
/// that gets `jsonEncode`d, UTF-8 encoded, AEAD-encrypted under the
/// owning Person's key, and stored in the `medications.payload` BLOB.
///
/// **This wire format is forever-compatible.** Every historical `v` value
/// the app has ever emitted must be decodable. Bumping
/// [currentSchemaVersion] requires an ADR and a round-trip test per
/// version.
///
/// Schema history:
///
/// * **v1** — name, dose, form, prescriber, notes, startDate, endDate.
/// * **v2** — adds `schedule` (kind + times + weekdays). v1 payloads
///   decode to `MedicationSchedule.asNeeded` so legacy rows don't
///   accidentally produce reminders.
class EncryptedMedicationPayload {
  const EncryptedMedicationPayload({
    required this.schemaVersion,
    required this.name,
    required this.schedule,
    this.dose,
    this.form,
    this.prescriber,
    this.notes,
    this.startDate,
    this.endDate,
  });

  /// Decode a JSON map previously produced by `toJson` (possibly by an
  /// older build). Throws [FormatException] on missing required fields
  /// and [UnsupportedError] on a version newer than this build.
  factory EncryptedMedicationPayload.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['v'];
    if (rawVersion is! int) {
      throw const FormatException(
        'EncryptedMedicationPayload JSON is missing integer "v" field',
      );
    }
    if (rawVersion < 1) {
      throw FormatException(
        'EncryptedMedicationPayload JSON has invalid "v": $rawVersion',
      );
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedError(
        'EncryptedMedicationPayload JSON "v"=$rawVersion is newer than '
        'this build supports (v$currentSchemaVersion). Upgrade the app.',
      );
    }
    final name = json['name'];
    if (name is! String) {
      throw const FormatException(
        'EncryptedMedicationPayload JSON is missing "name"',
      );
    }
    final startRaw = json['startDate'];
    final endRaw = json['endDate'];
    return EncryptedMedicationPayload(
      schemaVersion: rawVersion,
      name: name,
      dose: json['dose'] as String?,
      form: MedicationForm.fromWireName(json['form'] as String?),
      prescriber: json['prescriber'] as String?,
      notes: json['notes'] as String?,
      startDate: startRaw is String ? _parseDateOnly(startRaw) : null,
      endDate: endRaw is String ? _parseDateOnly(endRaw) : null,
      schedule: _decodeSchedule(json['schedule']),
    );
  }

  /// Parse a `YYYY-MM-DD` string as a UTC midnight instant. Same rationale
  /// as on `EncryptedPersonPayload` — preserve the calendar date across
  /// timezones.
  static DateTime _parseDateOnly(String s) {
    final parts = s.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date-only string: "$s"');
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      throw FormatException('Invalid date-only string: "$s"');
    }
    return DateTime.utc(y, m, d);
  }

  /// Decode the `schedule` sub-object. Missing / malformed schedules
  /// fall back to [MedicationSchedule.asNeeded] — this keeps v1 payloads
  /// working and tolerates partial corruption without hiding the row.
  static MedicationSchedule _decodeSchedule(Object? raw) {
    if (raw is! Map) return MedicationSchedule.asNeeded;
    final kind = ScheduleKind.fromWireName(raw['kind'] as String?);
    if (kind == ScheduleKind.asNeeded) return MedicationSchedule.asNeeded;

    final timesRaw = raw['times'];
    final times = <ScheduledTime>[];
    if (timesRaw is List) {
      for (final t in timesRaw) {
        if (t is! String) continue;
        try {
          times.add(ScheduledTime.fromWireString(t));
        } on FormatException {
          // Skip unparseable entries rather than failing the whole row.
        }
      }
    }

    final daysRaw = raw['days'];
    final days = <int>{};
    if (daysRaw is List) {
      for (final d in daysRaw) {
        if (d is int && d >= 1 && d <= 7) days.add(d);
      }
    }

    // Enforce the domain invariants here rather than letting the
    // assertion in `MedicationSchedule` fire in production: if a payload
    // is self-contradictory (weekly with no days, daily with a days list)
    // we clean it up instead of crashing.
    if (kind == ScheduleKind.weekly && days.isEmpty) {
      return MedicationSchedule.asNeeded;
    }
    return MedicationSchedule(
      kind: kind,
      times: _sortTimes(times),
      days: kind == ScheduleKind.weekly ? days : const <int>{},
    );
  }

  /// Sort + dedupe on `minutesSinceMidnight` so equivalent schedules
  /// serialise to byte-identical JSON (modulo other fields).
  static List<ScheduledTime> _sortTimes(Iterable<ScheduledTime> times) {
    final seen = <int>{};
    final sorted = <ScheduledTime>[];
    for (final t in times) {
      if (seen.add(t.minutesSinceMidnight)) sorted.add(t);
    }
    sorted.sort(
      (a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
    );
    return sorted;
  }

  /// The schema version written by this build.
  ///
  /// Bumped from 1 → 2 when the optional `schedule` sub-object was added.
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String name;
  final String? dose;
  final MedicationForm? form;
  final String? prescriber;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final MedicationSchedule schedule;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        if (dose != null) 'dose': dose,
        if (form != null) 'form': form!.wireName,
        if (prescriber != null) 'prescriber': prescriber,
        if (notes != null) 'notes': notes,
        if (startDate != null) 'startDate': _dateOnly(startDate!),
        if (endDate != null) 'endDate': _dateOnly(endDate!),
        // Only emit `schedule` for non-default values. A payload that
        // contains the default `asNeeded` schedule is byte-identical to
        // a v1 payload apart from `v`, which keeps diffs small when
        // Phase 2 sync ships.
        if (schedule.kind != ScheduleKind.asNeeded)
          'schedule': _encodeSchedule(schedule),
      };

  static Map<String, dynamic> _encodeSchedule(MedicationSchedule s) {
    final sorted = _sortTimes(s.times);
    final json = <String, dynamic>{
      'kind': s.kind.wireName,
      'times': [for (final t in sorted) t.toWireString()],
    };
    if (s.kind == ScheduleKind.weekly) {
      final days = s.days.toList()..sort();
      json['days'] = days;
    }
    return json;
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
