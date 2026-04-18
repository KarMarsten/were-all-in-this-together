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
/// * **v3** — adds optional `nagIntervalMinutes` and `nagCap` per-med
///   overrides. v1/v2 payloads decode with both fields `null`, which
///   means "inherit the device-wide default".
/// * **v4** — adds optional `prescriberId`, a link to a `CareProvider`
///   owned by the same Person. The free-text `prescriber` field is
///   preserved as a fallback (e.g. one-off urgent-care visits), so
///   v1-v3 payloads round-trip unchanged with `prescriberId = null`.
class EncryptedMedicationPayload {
  const EncryptedMedicationPayload({
    required this.schemaVersion,
    required this.name,
    required this.schedule,
    this.dose,
    this.form,
    this.prescriber,
    this.prescriberId,
    this.notes,
    this.startDate,
    this.endDate,
    this.nagIntervalMinutesOverride,
    this.nagCapOverride,
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
      prescriberId: json['prescriberId'] as String?,
      notes: json['notes'] as String?,
      startDate: startRaw is String ? _parseDateOnly(startRaw) : null,
      endDate: endRaw is String ? _parseDateOnly(endRaw) : null,
      schedule: MedicationSchedule.fromWireJson(json['schedule']),
      nagIntervalMinutesOverride: _asInt(json['nagIntervalMinutes']),
      nagCapOverride: _asInt(json['nagCap']),
    );
  }

  /// Narrow an untyped JSON value to `int?`. Tolerates `num`s that
  /// happen to decode as `double` (round-trip via plists can do this)
  /// but rejects strings — we'd rather drop a bad value than let a
  /// `"10"` sneak through as something the scheduler must clamp
  /// later.
  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return null;
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

  /// The schema version written by this build.
  ///
  /// * 1 → 2: added optional `schedule` sub-object.
  /// * 2 → 3: added optional `nagIntervalMinutes` / `nagCap` overrides.
  /// * 3 → 4: added optional `prescriberId` linking to a `CareProvider`.
  static const int currentSchemaVersion = 4;

  final int schemaVersion;
  final String name;
  final String? dose;
  final MedicationForm? form;
  final String? prescriber;

  /// Optional link to a `CareProvider` owned by the same Person. Kept
  /// as a reference rather than an embedded copy so a provider name /
  /// phone change updates every medication prescribed by them in one
  /// place. The free-text [prescriber] stays available for one-off
  /// prescribers that aren't saved as Providers.
  final String? prescriberId;

  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final MedicationSchedule schedule;
  final int? nagIntervalMinutesOverride;
  final int? nagCapOverride;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': schemaVersion,
        'name': name,
        if (dose != null) 'dose': dose,
        if (form != null) 'form': form!.wireName,
        if (prescriber != null) 'prescriber': prescriber,
        if (prescriberId != null) 'prescriberId': prescriberId,
        if (notes != null) 'notes': notes,
        if (startDate != null) 'startDate': _dateOnly(startDate!),
        if (endDate != null) 'endDate': _dateOnly(endDate!),
        // Only emit `schedule` for non-default values. A payload that
        // contains the default `asNeeded` schedule is byte-identical to
        // a v1 payload apart from `v`, which keeps diffs small when
        // Phase 2 sync ships.
        if (schedule.kind != ScheduleKind.asNeeded)
          'schedule': schedule.toWireJson(),
        if (nagIntervalMinutesOverride != null)
          'nagIntervalMinutes': nagIntervalMinutesOverride,
        if (nagCapOverride != null) 'nagCap': nagCapOverride,
      };

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
