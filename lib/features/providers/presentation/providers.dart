import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/data/care_provider_repository.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';

/// Active (non-archived) care providers for the currently-active Person.
///
/// Watches [activePersonIdProvider] via `.future`, so the list naturally
/// re-resolves when the active Person changes. Mutations local to the
/// providers domain (create / update / archive / restore) must call
/// [invalidateCareProvidersState] below.
///
/// Returns `[]` when no Person is active — an empty roster is a real
/// UI state the list screen handles with a "Add someone first" prompt.
final careProvidersListProvider =
    FutureProvider<List<CareProvider>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <CareProvider>[];
  final repo = ref.watch(careProviderRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

/// Archived care providers for the active Person, newest-archived first.
///
/// Rendered below the active list so past references (e.g. a retired
/// pediatrician still linked to historical medication rows) stay
/// visible but out of the way.
final archivedCareProvidersListProvider =
    FutureProvider<List<CareProvider>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <CareProvider>[];
  final repo = ref.watch(careProviderRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

/// Refresh every provider that derives from "which providers exist".
///
/// Must be called after any create / update / archive / restore so the
/// list screen and the archived section both re-fetch.
void invalidateCareProvidersState(WidgetRef ref) {
  ref
    ..invalidate(careProvidersListProvider)
    ..invalidate(archivedCareProvidersListProvider);
}
