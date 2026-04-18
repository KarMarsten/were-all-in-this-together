import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Compare two snapshots of a [Medication] and produce a list of
/// field-level diffs suitable for a [MedicationEvent].
///
/// Field choice is deliberate: we track medically-meaningful changes
/// (name, dose, form, prescriber link, prescriber note, schedule,
/// start/end date) and *not* free-text notes or reminder-behavior
/// overrides (`nagIntervalMinutesOverride`, `nagCapOverride`).
/// Reasons:
///
/// * **Notes** change casually — "felt tired today" — and shouldn't
///   crowd the regimen timeline. The free-text history lives in the
///   note itself.
/// * **Reminder overrides** are behavioral preferences, not part of
///   the clinical regimen. Recording them as history would imply a
///   significance they don't have.
///
/// Returns an empty list if nothing medically-meaningful changed
/// (the caller should *not* emit a [MedicationEventKind.fieldsChanged]
/// event in that case — a save that only edited notes should leave
/// the timeline quiet).
///
/// [before] may be `null` for a brand-new medication, in which case
/// every non-null field on [after] produces a "set" diff. In
/// practice the caller for `create` passes `null` and uses
/// [MedicationEventKind.created] with empty diffs instead; this
/// nullable is kept for symmetry and unit testing.
List<MedicationFieldDiff> diffMedicationFields({
  required Medication? before,
  required Medication after,
}) {
  final diffs = <MedicationFieldDiff>[];

  void add(String field, String? prev, String? curr) {
    if (prev == curr) return;
    diffs.add(
      MedicationFieldDiff(field: field, previous: prev, current: curr),
    );
  }

  add('name', before?.name, after.name);
  add('dose', _nullIfBlank(before?.dose), _nullIfBlank(after.dose));
  add('form', before?.form?.wireName, after.form?.wireName);
  add(
    'prescriber',
    _nullIfBlank(before?.prescriber),
    _nullIfBlank(after.prescriber),
  );
  add('prescriberId', before?.prescriberId, after.prescriberId);
  add(
    'startDate',
    _dateToWire(before?.startDate),
    _dateToWire(after.startDate),
  );
  add('endDate', _dateToWire(before?.endDate), _dateToWire(after.endDate));
  add(
    'schedule',
    before == null ? null : _scheduleToWire(before.schedule),
    _scheduleToWire(after.schedule),
  );

  return diffs;
}

String? _nullIfBlank(String? s) {
  if (s == null) return null;
  final trimmed = s.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _dateToWire(DateTime? d) {
  if (d == null) return null;
  final utc = d.toUtc();
  final y = utc.year.toString().padLeft(4, '0');
  final m = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Compact, wire-stable stringification of a schedule, chosen over a
/// localized human label so the stored diff is reproducible across
/// locales and across refactors of UI copy.
///
/// Examples:
/// * `asNeeded`
/// * `daily@08:00,20:00`
/// * `weekly[1,3,5]@09:00`
String _scheduleToWire(MedicationSchedule s) {
  switch (s.kind) {
    case ScheduleKind.asNeeded:
      return 'asNeeded';
    case ScheduleKind.daily:
      final times = _sortedTimes(s);
      return times.isEmpty ? 'daily' : 'daily@$times';
    case ScheduleKind.weekly:
      final days = (s.days.toList()..sort()).join(',');
      final times = _sortedTimes(s);
      final timesPart = times.isEmpty ? '' : '@$times';
      return 'weekly[$days]$timesPart';
  }
}

String _sortedTimes(MedicationSchedule s) {
  final wire = [for (final t in s.times) t.toWireString()]..sort();
  return wire.join(',');
}
