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

/// Snapshot of everyone a medication / appointment / etc. can link to
/// as a prescriber or treating provider.
///
/// Both lists are scoped to the given Person. Archived providers stay
/// in the picker so history doesn't break when a provider is retired
/// or replaced — see the Medication form where they render as
/// "(archived)" below the active group.
class CareProviderPickerData {
  const CareProviderPickerData({
    required this.active,
    required this.archived,
  });

  final List<CareProvider> active;
  final List<CareProvider> archived;

  /// Convenience for lookups by id across both lists. Archived
  /// providers are included because a stored `prescriberId` may point
  /// to one.
  CareProvider? byId(String id) {
    for (final list in [active, archived]) {
      for (final p in list) {
        if (p.id == id) return p;
      }
    }
    return null;
  }
}

/// Picker data source keyed on a specific Person.
///
/// We key on `personId` rather than `activePersonId` because edit
/// flows (e.g. editing a medication under a non-active Person via a
/// deep link) need providers scoped to the *row's* Person, not the
/// currently selected one. Create flows should still pass the active
/// Person's id.
// ignore: specify_nonobvious_property_types
final careProviderPickerProvider =
    FutureProvider.family<CareProviderPickerData, String>(
  (ref, personId) async {
    final repo = ref.watch(careProviderRepositoryProvider);
    final active = await repo.listActiveForPerson(personId);
    final archived = await repo.listArchivedForPerson(personId);
    return CareProviderPickerData(active: active, archived: archived);
  },
);

/// Refresh every provider that derives from "which providers exist".
///
/// Must be called after any create / update / archive / restore so the
/// list screen and the archived section both re-fetch.
void invalidateCareProvidersState(WidgetRef ref) {
  ref
    ..invalidate(careProvidersListProvider)
    ..invalidate(archivedCareProvidersListProvider)
    ..invalidate(careProviderPickerProvider);
}
