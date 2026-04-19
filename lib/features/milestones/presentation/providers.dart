import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

/// Active (non-archived) milestones for the currently-active
/// Person, most recent first.
///
/// Watches [activePersonIdProvider] via `.future` so the list
/// naturally re-resolves when the active Person changes. Mutations
/// local to the milestones domain (create / update / archive /
/// restore) must call [invalidateMilestonesState] below.
///
/// Returns `[]` when no Person is active — an empty roster is a
/// real UI state the list screen handles with a dedicated
/// "Add someone first" prompt.
final activeMilestonesProvider =
    FutureProvider<List<Milestone>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Milestone>[];
  final repo = ref.watch(milestoneRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

/// Archived milestones for the active Person, newest-archived
/// first.
final archivedMilestonesProvider =
    FutureProvider<List<Milestone>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Milestone>[];
  final repo = ref.watch(milestoneRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

/// Refresh every provider that derives from "which milestones
/// exist". Must be called after any create / update / archive /
/// restore so the list screen's sections re-fetch.
void invalidateMilestonesState(WidgetRef ref) {
  ref
    ..invalidate(activeMilestonesProvider)
    ..invalidate(archivedMilestonesProvider)
    ..invalidate(allTodayMilestonesProvider)
    ..invalidate(todayItemsProvider);
}
