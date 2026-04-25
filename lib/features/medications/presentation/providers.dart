import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

/// Active (non-archived) medications for the currently-active Person.
///
/// Watches [activePersonIdProvider] via `.future`, so the list naturally
/// re-resolves when the active Person changes (switch, first-add, delete
/// of the active Person). Mutations local to the medication domain
/// (create/update/archive/restore) must explicitly call
/// [invalidateMedicationsState] below.
///
/// Returns `[]` when the roster is empty. We don't throw — an empty
/// roster is a real UI state the list screen handles cleanly.
final medicationsListProvider = FutureProvider<List<Medication>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Medication>[];
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

/// Archived medications for the active Person, newest-archived first.
final archivedMedicationsListProvider =
    FutureProvider<List<Medication>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Medication>[];
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

/// Refresh every provider that derives from "which meds exist".
///
/// Must be called after any create / update / archive / restore so the
/// list screen and the archived section both re-fetch. Active-person
/// changes invalidate automatically via the `.future` watch above.
void invalidateMedicationsState(WidgetRef ref) {
  ref
    ..invalidate(medicationsListProvider)
    ..invalidate(archivedMedicationsListProvider)
    // Invalidating the roster-wide list keeps one-shot reminder
    // reconciliation pointed at fresh data after the form flow saves.
    ..invalidate(allActiveMedicationsProvider)
    // Any medication mutation also appends a history event, so the
    // timeline has to re-fetch.
    ..invalidate(medicationHistoryProvider);
}

/// Timeline of events for a medication, most-recent-first.
///
/// Family-keyed on `medicationId` so opening the history of one
/// medication doesn't cache the others' lists. Archived events are
/// excluded server-side.
// ignore: specify_nonobvious_property_types
final medicationHistoryProvider =
    FutureProvider.family<List<MedicationEvent>, String>(
  (ref, medicationId) async {
    final repo = ref.watch(medicationEventRepositoryProvider);
    return repo.listForMedication(medicationId);
  },
);

/// Active (non-archived) medication groups for the currently-active
/// Person. Mirrors [medicationsListProvider] in shape and invalidation
/// rules.
final medicationGroupsListProvider =
    FutureProvider<List<MedicationGroup>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <MedicationGroup>[];
  final repo = ref.watch(medicationGroupRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

/// Archived groups for the active Person.
final archivedMedicationGroupsListProvider =
    FutureProvider<List<MedicationGroup>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <MedicationGroup>[];
  final repo = ref.watch(medicationGroupRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

/// Refresh the group-list providers after a group mutation. Also
/// nudges the Today items pipeline through
/// [allActiveMedicationGroupsProvider] so a newly-created group shows
/// up on Today without a pull-to-refresh.
void invalidateGroupsState(WidgetRef ref) {
  ref
    ..invalidate(medicationGroupsListProvider)
    ..invalidate(archivedMedicationGroupsListProvider)
    ..invalidate(allActiveMedicationGroupsProvider);
}
