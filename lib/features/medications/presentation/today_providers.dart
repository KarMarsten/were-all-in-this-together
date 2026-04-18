import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';
import 'package:were_all_in_this_together/features/medications/domain/today_item.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

/// Composite identity of a single scheduled dose: `(medicationId,
/// scheduledAtUtcMs)`. Same shape as the DB's unique-key on
/// `dose_logs`, so callers can zip logs and doses together without
/// translating.
typedef DoseIdentity = ({String medicationId, int scheduledAtUtcMs});

DoseIdentity identityOfDose(ScheduledDose d) => (
      medicationId: d.medicationId,
      scheduledAtUtcMs: d.scheduledAt.toUtc().millisecondsSinceEpoch,
    );

DoseIdentity identityOfLog(DoseLog l) => (
      medicationId: l.medicationId,
      scheduledAtUtcMs: l.scheduledAt.toUtc().millisecondsSinceEpoch,
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
/// invalidate this provider explicitly from
/// [invalidateMedicationGroupsState].
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
  return expandTodayItems(
    medications: medContexts,
    groups: groupContexts,
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
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

/// Refresh provider state after a medication-group write.
///
/// Invalidates the all-active-groups source, which cascades through
/// [todayItemsProvider] and [todayDoseLogsProvider] automatically.
void invalidateMedicationGroupsState(WidgetRef ref) {
  ref.invalidate(allActiveMedicationGroupsProvider);
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
