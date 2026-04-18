import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_schedule.freezed.dart';

/// How often a medication is taken.
///
/// Deliberately small. Three kinds cover ~every regimen we care about in
/// Phase 1 without inventing cron-like syntax:
///
/// * [asNeeded] — no scheduled times. Used for PRN meds, supplements the
///   user takes "when I remember", or meds whose schedule lives entirely
///   in the user's head. Won't produce reminders in PR 11.
/// * [daily] — one or more times every day.
/// * [weekly] — one or more times on a chosen set of weekdays.
///
/// Wire names are stable; renames would silently break historical
/// payloads.
enum ScheduleKind {
  asNeeded,
  daily,
  weekly;

  String get wireName => switch (this) {
        ScheduleKind.asNeeded => 'asNeeded',
        ScheduleKind.daily => 'daily',
        ScheduleKind.weekly => 'weekly',
      };

  /// Forward-compatible decode: any unknown `kind` string from a newer
  /// payload version falls back to `asNeeded` so the row still renders
  /// without spurious reminders.
  static ScheduleKind fromWireName(String? s) {
    for (final v in ScheduleKind.values) {
      if (v.wireName == s) return v;
    }
    return ScheduleKind.asNeeded;
  }
}

/// A clock time with no date or timezone, local to wherever the user is
/// when a reminder fires.
///
/// We deliberately don't use `flutter.material.TimeOfDay` here — this
/// type is used by the encrypted-payload serialiser too, and reusing a
/// Flutter widget-layer type there would couple wire format to the
/// framework.
@immutable
class ScheduledTime {
  const ScheduledTime({required this.hour, required this.minute})
      : assert(hour >= 0 && hour < 24, 'hour must be in 0..23'),
        assert(minute >= 0 && minute < 60, 'minute must be in 0..59');

  factory ScheduledTime.fromWireString(String s) {
    final parts = s.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid ScheduledTime: "$s"');
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      throw FormatException('Invalid ScheduledTime: "$s"');
    }
    return ScheduledTime(hour: h, minute: m);
  }

  final int hour;
  final int minute;

  /// Wire format: zero-padded 24-hour `HH:mm`.
  String toWireString() =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  /// Minutes since midnight — useful for sorting reminder times.
  int get minutesSinceMidnight => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTime &&
          other.hour == hour &&
          other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ScheduledTime(${toWireString()})';
}

/// A medication's dosing schedule.
///
/// Shape invariants (not enforced by constructor — would prevent a
/// `const` default — but upheld by all callers and by
/// `EncryptedMedicationPayload` on decode):
///
/// * For [ScheduleKind.asNeeded], [times] and [days] are empty.
/// * For [ScheduleKind.daily], [days] is empty (implicit all seven).
/// * For [ScheduleKind.weekly], [days] is non-empty and every entry is
///   in 1..7 (ISO-8601 Monday..Sunday).
///
/// Times are stored sorted and de-duplicated by `EncryptedMedicationPayload`
/// on write so equivalent schedules serialise byte-identically.
@freezed
abstract class MedicationSchedule with _$MedicationSchedule {
  const factory MedicationSchedule({
    required ScheduleKind kind,
    @Default(<ScheduledTime>[]) List<ScheduledTime> times,

    /// ISO-8601 weekdays: 1 = Monday ... 7 = Sunday. Empty for
    /// [ScheduleKind.daily] and [ScheduleKind.asNeeded].
    @Default(<int>{}) Set<int> days,
  }) = _MedicationSchedule;

  const MedicationSchedule._();

  /// Tolerant decode from a wire-format JSON map (the `schedule`
  /// sub-object on encrypted payloads). Used by both
  /// `EncryptedMedicationPayload` and `EncryptedMedicationGroupPayload`
  /// so the format stays consistent across both entities.
  ///
  /// Rules — all in service of "a partially-corrupt payload should
  /// degrade gracefully rather than hide the row":
  ///
  /// * `null` / non-map / missing → [asNeeded].
  /// * Unknown `kind` → [asNeeded] (see [ScheduleKind.fromWireName]).
  /// * Unparseable entries in `times` are dropped, not fatal.
  /// * `days` entries outside 1..7 are dropped.
  /// * Weekly with an empty `days` list is demoted to [asNeeded],
  ///   matching the domain invariant upheld by the UI.
  ///
  // Can't be a factory constructor because `MedicationSchedule` is a
  // freezed abstract class whose only public constructors are the
  // generated ones; a user-defined factory would clash with freezed's
  // codegen. Keeping this as a static factory method.
  // ignore: prefer_constructors_over_static_methods
  static MedicationSchedule fromWireJson(Object? raw) {
    if (raw is! Map) return asNeeded;
    final kind = ScheduleKind.fromWireName(raw['kind'] as String?);
    if (kind == ScheduleKind.asNeeded) return asNeeded;

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

    if (kind == ScheduleKind.weekly && days.isEmpty) {
      return asNeeded;
    }
    return MedicationSchedule(
      kind: kind,
      times: _sortAndDedupe(times),
      days: kind == ScheduleKind.weekly ? days : const <int>{},
    );
  }

  /// Encode as the canonical wire-format JSON map. Times are sorted +
  /// de-duplicated on `minutesSinceMidnight` so equivalent schedules
  /// serialise byte-identically — useful both for Phase 2 sync diffs
  /// and for making "same" schedules actually `==` after a round-trip.
  Map<String, dynamic> toWireJson() {
    final sorted = _sortAndDedupe(times);
    final json = <String, dynamic>{
      'kind': kind.wireName,
      'times': [for (final t in sorted) t.toWireString()],
    };
    if (kind == ScheduleKind.weekly) {
      final sortedDays = days.toList()..sort();
      json['days'] = sortedDays;
    }
    return json;
  }

  static List<ScheduledTime> _sortAndDedupe(Iterable<ScheduledTime> times) {
    final seen = <int>{};
    final out = <ScheduledTime>[];
    for (final t in times) {
      if (seen.add(t.minutesSinceMidnight)) out.add(t);
    }
    out.sort(
      (a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
    );
    return out;
  }

  /// Canonical "no schedule" value. Default for new meds and for v1
  /// payloads decoded by this build.
  static const MedicationSchedule asNeeded =
      MedicationSchedule(kind: ScheduleKind.asNeeded);

  /// Whether this schedule should produce reminders. Encoded as a single
  /// getter so UI + notification scheduler can share the rule.
  bool get isReminderEligible =>
      kind != ScheduleKind.asNeeded && times.isNotEmpty;
}
