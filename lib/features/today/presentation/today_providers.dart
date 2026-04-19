import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/appointments/presentation/providers.dart';
import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/today/domain/today_appointment_item.dart';
import 'package:were_all_in_this_together/features/today/domain/today_item.dart';
import 'package:were_all_in_this_together/features/today/domain/today_milestone_item.dart';

/// Convenience: the [DoseIdentity] of a [ScheduledDose]. The log
/// side lives in `dose_log.dart` (as `identityOfLog`) so the
/// notifications layer can use it without importing presentation
/// code.
DoseIdentity identityOfDose(ScheduledDose d) => (
      medicationId: d.medicationId,
      scheduledAtUtcMs: d.scheduledAt.toUtc().millisecondsSinceEpoch,
    );

/// "Now" as a provider so widget tests can override the clock.
///
/// The Today screen is inherently time-sensitive: it needs to know
/// when midnight is and which doses are past/upcoming. Making the
/// clock injectable keeps tests hermetic without reaching for
/// `withClock`.
final todayClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Every scheduled dose in the device's *current local calendar day*.
///
/// Reuses [allActiveMedicationsProvider] as the source so that every
/// medication mutation (create / update / archive / restore) and every
/// Person roster change flows through here automatically — the
/// reminders pipeline and the Today screen are two views of the same
/// underlying "what is the user currently tracking?" list.
final todayScheduledDosesProvider =
    FutureProvider<List<ScheduledDose>>((ref) async {
  final now = ref.watch(todayClockProvider)();
  final owned = await ref.watch(allActiveMedicationsProvider.future);

  final contexts = [
    for (final o in owned)
      DoseSchedulingContext(
        medication: o.medication,
        personDisplayName: o.personDisplayName,
      ),
  ];

  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfDay.add(const Duration(days: 1));
  return expandDoses(
    medications: contexts,
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
});

/// Flat list of every active medication group across all people,
/// paired with the owning Person's display name.
///
/// Analogous to [allActiveMedicationsProvider]: a single source of
/// truth for "which groups should the Today screen consider?" that
/// invalidates when the Person roster changes. Group repo mutations
/// invalidate this provider explicitly from `invalidateGroupsState`
/// in the medications presentation layer.
final allActiveMedicationGroupsProvider =
    FutureProvider<List<OwnedMedicationGroup>>((ref) async {
  final people = await ref.watch(peopleListProvider.future);
  final repo = ref.watch(medicationGroupRepositoryProvider);
  final result = <OwnedMedicationGroup>[];
  for (final person in people) {
    final groups = await repo.listActiveForPerson(person.id);
    for (final g in groups) {
      result.add(
        OwnedMedicationGroup(group: g, personDisplayName: person.displayName),
      );
    }
  }
  return result;
});

/// Every Today row (solo or group) for the device's current local
/// calendar day, already de-duplicated and sorted.
///
/// This is the canonical feed the Today screen renders. Depends on
/// both [todayScheduledDosesProvider] and
/// [allActiveMedicationGroupsProvider], so any upstream change
/// (Person / med / group / archive) flows through automatically.
final todayItemsProvider = FutureProvider<List<TodayItem>>((ref) async {
  final now = ref.watch(todayClockProvider)();
  final owned = await ref.watch(allActiveMedicationsProvider.future);
  final ownedGroups = await ref.watch(allActiveMedicationGroupsProvider.future);
  final todayAppts = await ref.watch(allTodayAppointmentsProvider.future);
  final todayMilestoneSeeds =
      await ref.watch(allTodayMilestonesProvider.future);

  final medContexts = [
    for (final o in owned)
      DoseSchedulingContext(
        medication: o.medication,
        personDisplayName: o.personDisplayName,
      ),
  ];
  final groupContexts = [
    for (final g in ownedGroups)
      GroupSchedulingContext(
        group: g.group,
        personDisplayName: g.personDisplayName,
      ),
  ];

  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfDay.add(const Duration(days: 1));
  final medItems = expandTodayItems(
    medications: medContexts,
    groups: groupContexts,
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
  final apptItems = expandTodayAppointmentItems(
    appointments: todayAppts,
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
  final milestoneItems = expandTodayMilestoneItems(
    milestones: todayMilestoneSeeds,
    now: now,
  );

  // Single merged list, sorted by scheduledAt so a 09:00 visit slots
  // between the 08:00 and 10:00 doses. Milestone anniversaries share
  // the same local-midnight anchor so they sort ahead of morning
  // doses; ties fall back to `occurredAt` inside
  // `expandTodayMilestoneItems`.
  final combined = <TodayItem>[
    ...medItems,
    ...apptItems,
    ...milestoneItems,
  ]..sort((a, b) {
      final byTime = a.scheduledAt.compareTo(b.scheduledAt);
      if (byTime != 0) return byTime;
      return _todayStableSortKey(a).compareTo(_todayStableSortKey(b));
    });
  return combined;
});

/// Every active milestone across all managed people, paired with
/// each Person's display name — raw input for
/// [expandTodayMilestoneItems], which filters to "on this day"
/// anniversaries.
///
/// Scoped roster-wide (not active-Person-only) so Today matches how
/// [allTodayAppointmentsProvider] works: a parent sees a child's
/// anniversary row even when another Person is selected elsewhere.
final allTodayMilestonesProvider =
    FutureProvider<List<OwnedTodayMilestone>>((ref) async {
  final people = await ref.watch(peopleListProvider.future);
  final repo = ref.watch(milestoneRepositoryProvider);
  final result = <OwnedTodayMilestone>[];
  for (final person in people) {
    final milestones = await repo.listActiveForPerson(person.id);
    for (final m in milestones) {
      result.add(
        OwnedTodayMilestone(
          milestone: m,
          personDisplayName: person.displayName,
        ),
      );
    }
  }
  return result;
});

/// Logs indexed by `(medicationId, scheduledAtUtcMs)` for today's
/// doses only.
///
/// Queries the union of medication ids appearing across today's
/// rendered items — both solo doses and every group member — so a
/// group bundle can look up per-member log state.
final todayDoseLogsProvider =
    FutureProvider<Map<DoseIdentity, DoseLog>>((ref) async {
  final now = ref.watch(todayClockProvider)();
  final items = await ref.watch(todayItemsProvider.future);
  if (items.isEmpty) return const <DoseIdentity, DoseLog>{};

  final medIds = <String>{};
  for (final item in items) {
    if (item is TodaySoloItem) {
      medIds.add(item.dose.medicationId);
    } else if (item is TodayGroupItem) {
      for (final m in item.members) {
        medIds.add(m.medicationId);
      }
    }
  }
  if (medIds.isEmpty) return const <DoseIdentity, DoseLog>{};

  final repo = ref.watch(doseLogRepositoryProvider);
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfDay.add(const Duration(days: 1));
  final logs = await repo.forMedicationsInRange(
    medicationIds: medIds,
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
  return {for (final l in logs) identityOfLog(l): l};
});

/// Refresh the Today screen after a dose log write.
///
/// We only invalidate the logs provider — the schedule itself didn't
/// change, so recomputing it would just waste work.
void invalidateDoseLogsState(WidgetRef ref) {
  ref.invalidate(todayDoseLogsProvider);
}

/// One active [MedicationGroup] paired with its owning Person's
/// display name. Mirror of `OwnedMedication` from the notifications
/// layer.
@immutable
class OwnedMedicationGroup {
  const OwnedMedicationGroup({
    required this.group,
    required this.personDisplayName,
  });

  final MedicationGroup group;
  final String personDisplayName;
}

/// Stable ordering when two [TodayItem]s share the same
/// [TodayItem.scheduledAt] (e.g. several milestone anniversaries at
/// local midnight).
String _todayStableSortKey(TodayItem item) {
  if (item is TodaySoloItem) {
    final d = item.dose;
    return 'a:${d.medicationId}:${d.scheduledAt.millisecondsSinceEpoch}';
  }
  if (item is TodayGroupItem) {
    return 'b:${item.groupId}:${item.scheduledAt.millisecondsSinceEpoch}';
  }
  if (item is TodayAppointmentItem) {
    return 'c:${item.appointment.id}';
  }
  if (item is TodayMilestoneItem) {
    return 'd:${item.milestone.id}';
  }
  return 'z:${item.runtimeType}';
}
