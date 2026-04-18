import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

export 'package:were_all_in_this_together/features/medications/domain/medication.dart'
    show MedicationForm;

/// One concrete dose instance derived from a medication's schedule on
/// a specific calendar day.
///
/// Doses are *derived*, not persisted. The Today screen computes them
/// from the medication list at render time; dose logs only record what
/// actually happened with them.
///
/// Equality (and therefore `Set` / `Map` keying) is on
/// `(medicationId, scheduledAt)` — the same identity used by
/// `DoseLog`. This lets the UI zip logs and doses together trivially.
@immutable
class ScheduledDose {
  const ScheduledDose({
    required this.medicationId,
    required this.personId,
    required this.medicationName,
    required this.personDisplayName,
    required this.scheduledAt,
    this.dose,
    this.form,
  });

  final String medicationId;
  final String personId;
  final String medicationName;
  final String personDisplayName;

  /// Dose instance in UTC. Local display is the view layer's problem.
  final DateTime scheduledAt;
  final String? dose;
  final MedicationForm? form;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledDose &&
          other.medicationId == medicationId &&
          other.scheduledAt == scheduledAt;

  @override
  int get hashCode => Object.hash(medicationId, scheduledAt);

  @override
  String toString() =>
      'ScheduledDose(med=$medicationName, at=$scheduledAt, '
      'person=$personDisplayName)';
}

/// One (Medication, owning Person's display name) pair. Same shape as
/// `OwnedMedication` in the notifications layer — duplicated here to
/// avoid a back-import from presentation into domain. If we grow a
/// third consumer it's worth extracting into `core/`.
@immutable
class DoseSchedulingContext {
  const DoseSchedulingContext({
    required this.medication,
    required this.personDisplayName,
  });

  final Medication medication;
  final String personDisplayName;
}

/// Expand a set of medications into every dose they produce between
/// [fromInclusive] and [toExclusive].
///
/// Both bounds are treated as instants, not dates — the caller is
/// responsible for picking midnight-of-local-day boundaries. This
/// keeps the expander timezone-agnostic so unit tests can feed it UTC
/// bounds without threading a `tz.Location` through the API.
///
/// Rules:
///
/// * Archived or `asNeeded` meds contribute no doses — they have no
///   schedule. (Phase 2 may want to surface "you could take this" PRN
///   entries; out of scope here.)
/// * Schedules with no times contribute no doses.
/// * Daily schedules produce one dose per time, per day in range.
/// * Weekly schedules produce one dose per (day, time) pair whose
///   ISO-8601 weekday is in the schedule.
///
/// Doses are returned in ascending `scheduledAt` order. Stable sort
/// matters for the Today screen so a med with times `[08:00, 20:00]`
/// always renders Morning then Evening.
List<ScheduledDose> expandDoses({
  required Iterable<DoseSchedulingContext> medications,
  required DateTime fromInclusive,
  required DateTime toExclusive,
}) {
  assert(
    !toExclusive.isBefore(fromInclusive),
    'toExclusive must not be before fromInclusive',
  );

  final result = <ScheduledDose>[];
  for (final ctx in medications) {
    final med = ctx.medication;
    if (med.deletedAt != null) continue;
    if (!med.schedule.isReminderEligible) continue;

    // Walk the range one calendar day at a time. We use the local
    // wall-clock date of each boundary to decide whether to produce
    // doses, because schedules are written in local time.
    final fromLocal = fromInclusive.toLocal();
    final toLocal = toExclusive.toLocal();
    var cursor = DateTime(fromLocal.year, fromLocal.month, fromLocal.day);
    final endLocal = DateTime(toLocal.year, toLocal.month, toLocal.day);

    // If `toExclusive` is strictly after midnight on its day, include
    // that day too — callers typically pass `midnight + 24h`.
    final hasPartialEndDay =
        toLocal.hour != 0 || toLocal.minute != 0 || toLocal.second != 0;

    while (!cursor.isAfter(endLocal)) {
      if (cursor == endLocal && !hasPartialEndDay) break;

      final isoWeekday = cursor.weekday;
      final dayInSchedule = med.schedule.kind == ScheduleKind.daily ||
          (med.schedule.kind == ScheduleKind.weekly &&
              med.schedule.days.contains(isoWeekday));

      if (dayInSchedule) {
        for (final t in med.schedule.times) {
          final local = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            t.hour,
            t.minute,
          );
          final utc = local.toUtc();
          // Clip strictly to the requested range. The outer loop
          // already excludes full days; this handles times on the
          // boundary days.
          if (utc.isBefore(fromInclusive) || !utc.isBefore(toExclusive)) {
            continue;
          }
          result.add(
            ScheduledDose(
              medicationId: med.id,
              personId: med.personId,
              medicationName: med.name,
              personDisplayName: ctx.personDisplayName,
              scheduledAt: utc,
              dose: med.dose,
              form: med.form,
            ),
          );
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return result;
}
