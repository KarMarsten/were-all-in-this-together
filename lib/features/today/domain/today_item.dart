import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';

/// One row on the Today screen.
///
/// Either a single dose ([TodaySoloItem]) or a bundle of doses taken
/// together ([TodayGroupItem]). Common shape is exposed via abstract
/// getters rather than a shared constructor so each subclass can
/// derive them from its own backing data without a sentinel parent
/// state.
///
/// Intentionally not `sealed`: call sites handle both cases with
/// explicit `is` checks, and skipping `sealed` keeps us compatible
/// with toolchains that don't emit exhaustive-switch warnings
/// uniformly.
@immutable
abstract class TodayItem {
  const TodayItem();

  /// When this item is due, in UTC.
  DateTime get scheduledAt;

  /// Owning Person. Items always belong to exactly one Person — we
  /// do not mix groups across people.
  String get personId;
  String get personDisplayName;
}

/// A single medication's dose at a specific time. Used when the dose
/// isn't covered by any group at the same scheduled time.
@immutable
class TodaySoloItem extends TodayItem {
  const TodaySoloItem(this.dose);

  final ScheduledDose dose;

  @override
  DateTime get scheduledAt => dose.scheduledAt;
  @override
  String get personId => dose.personId;
  @override
  String get personDisplayName => dose.personDisplayName;
}

/// A group's bundle at a specific time, exposing the member doses so
/// the UI can show what's inside and so ACK-cascades can write a
/// DoseLog per member.
@immutable
class TodayGroupItem extends TodayItem {
  TodayGroupItem({
    required this.groupId,
    required this.groupName,
    required List<ScheduledDose> members,
    required this.scheduledAt,
    required this.personId,
    required this.personDisplayName,
  })  : assert(
          members.isNotEmpty,
          'group bundle must have at least one member',
        ),
        members = List.unmodifiable(members);

  final String groupId;
  final String groupName;

  /// Ordered the same way the group's `memberMedicationIds` list is
  /// ordered — caller intent drives display order.
  final List<ScheduledDose> members;

  @override
  final DateTime scheduledAt;
  @override
  final String personId;
  @override
  final String personDisplayName;
}

/// Expand medications and groups for the current local day into a
/// single list of [TodayItem]s, de-duplicated and sorted.
///
/// De-duplication rule: a solo dose whose `(medicationId, scheduledAt)`
/// is already covered by at least one group at the same time is
/// *hidden*. Groups retain the dose as a member regardless of whether
/// the med also has a standalone schedule — acting on any group
/// containing the dose logs that dose once.
///
/// If the same med is in multiple groups at the same time, all of
/// those group rows are kept: the user can see that it's in every
/// group, and logging via any one group settles them all (because
/// they share the underlying `(medicationId, scheduledAt)` key in
/// `dose_logs`). The other group rows just reflect the logged state.
List<TodayItem> expandTodayItems({
  required Iterable<DoseSchedulingContext> medications,
  required Iterable<GroupSchedulingContext> groups,
  required DateTime fromInclusive,
  required DateTime toExclusive,
}) {
  // 1. Expand individual doses once. We reuse this list for solos
  //    AND to look up concrete dose details (dose, form, etc.) when
  //    a group references a med.
  final allSoloDoses = expandDoses(
    medications: medications,
    fromInclusive: fromInclusive,
    toExclusive: toExclusive,
  );
  final dosesByMedId = <String, List<ScheduledDose>>{};
  for (final d in allSoloDoses) {
    dosesByMedId.putIfAbsent(d.medicationId, () => <ScheduledDose>[]).add(d);
  }

  // 2. Build a quick lookup of every medication we know about — used
  //    to turn a group's member id into a ScheduledDose shell even
  //    when the member med itself has no individual schedule (the
  //    group's schedule still creates the dose instance).
  final medsById = <String, DoseSchedulingContext>{
    for (final ctx in medications) ctx.medication.id: ctx,
  };

  // 3. Expand groups.
  final groupItems = <TodayGroupItem>[];
  final coveredByGroup = <_DoseKey>{};
  for (final gctx in groups) {
    final group = gctx.group;
    if (group.deletedAt != null) continue;
    if (!group.schedule.isReminderEligible) continue;

    final groupDoseTimes = _expandScheduleTimes(
      schedule: group.schedule,
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
    );
    if (groupDoseTimes.isEmpty) continue;

    // Members of the group that exist and belong to the same Person.
    // Cross-Person or deleted members are silently dropped — the group
    // stays valid, just missing that row.
    final memberMeds = <DoseSchedulingContext>[];
    for (final mid in group.memberMedicationIds) {
      final ctx = medsById[mid];
      if (ctx == null) continue;
      if (ctx.medication.personId != group.personId) continue;
      if (ctx.medication.deletedAt != null) continue;
      memberMeds.add(ctx);
    }
    if (memberMeds.isEmpty) continue;

    for (final utc in groupDoseTimes) {
      final memberDoses = <ScheduledDose>[
        for (final ctx in memberMeds)
          ScheduledDose(
            medicationId: ctx.medication.id,
            personId: ctx.medication.personId,
            medicationName: ctx.medication.name,
            personDisplayName: ctx.personDisplayName,
            scheduledAt: utc,
            dose: ctx.medication.dose,
            form: ctx.medication.form,
          ),
      ];
      groupItems.add(
        TodayGroupItem(
          groupId: group.id,
          groupName: group.name,
          members: memberDoses,
          scheduledAt: utc,
          personId: group.personId,
          personDisplayName: gctx.personDisplayName,
        ),
      );
      for (final d in memberDoses) {
        coveredByGroup.add(_keyOf(d));
      }
    }
  }

  // 4. Keep only solo doses that are NOT covered by any group.
  final soloItems = <TodaySoloItem>[
    for (final d in allSoloDoses)
      if (!coveredByGroup.contains(_keyOf(d))) TodaySoloItem(d),
  ];

  final combined = <TodayItem>[...soloItems, ...groupItems]
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return combined;
}

/// A (Medication-ish) context for a [MedicationGroup] — same shape
/// as [DoseSchedulingContext] but for groups. Defined alongside
/// [expandTodayItems] so presentation code doesn't back-import.
@immutable
class GroupSchedulingContext {
  const GroupSchedulingContext({
    required this.group,
    required this.personDisplayName,
  });

  final MedicationGroup group;
  final String personDisplayName;
}

/// Expand a schedule into the set of UTC instants it produces within
/// [fromInclusive, toExclusive). Exists as a helper rather than part
/// of [MedicationSchedule] because the local/UTC boundary handling is
/// specific to the Today screen's calendar-day window.
List<DateTime> _expandScheduleTimes({
  required MedicationSchedule schedule,
  required DateTime fromInclusive,
  required DateTime toExclusive,
}) {
  if (!schedule.isReminderEligible) return const <DateTime>[];

  final fromLocal = fromInclusive.toLocal();
  final toLocal = toExclusive.toLocal();
  var cursor = DateTime(fromLocal.year, fromLocal.month, fromLocal.day);
  final endLocal = DateTime(toLocal.year, toLocal.month, toLocal.day);
  final hasPartialEndDay =
      toLocal.hour != 0 || toLocal.minute != 0 || toLocal.second != 0;

  final out = <DateTime>[];
  while (!cursor.isAfter(endLocal)) {
    if (cursor == endLocal && !hasPartialEndDay) break;
    final isoWeekday = cursor.weekday;
    final dayInSchedule = schedule.kind == ScheduleKind.daily ||
        (schedule.kind == ScheduleKind.weekly &&
            schedule.days.contains(isoWeekday));
    if (dayInSchedule) {
      for (final t in schedule.times) {
        final local = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          t.hour,
          t.minute,
        );
        final utc = local.toUtc();
        if (utc.isBefore(fromInclusive) || !utc.isBefore(toExclusive)) {
          continue;
        }
        out.add(utc);
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  out.sort();
  return out;
}

@immutable
class _DoseKey {
  const _DoseKey(this.medicationId, this.scheduledAtUtcMs);
  final String medicationId;
  final int scheduledAtUtcMs;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DoseKey &&
          other.medicationId == medicationId &&
          other.scheduledAtUtcMs == scheduledAtUtcMs;
  @override
  int get hashCode => Object.hash(medicationId, scheduledAtUtcMs);
}

_DoseKey _keyOf(ScheduledDose d) =>
    _DoseKey(d.medicationId, d.scheduledAt.toUtc().millisecondsSinceEpoch);
