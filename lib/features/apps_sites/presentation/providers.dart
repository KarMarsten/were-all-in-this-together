import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/apps_sites/data/app_site_repository.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

final activeAppSitesProvider = FutureProvider<List<AppSite>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <AppSite>[];
  final repo = ref.watch(appSiteRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

final archivedAppSitesProvider = FutureProvider<List<AppSite>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <AppSite>[];
  final repo = ref.watch(appSiteRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

// Riverpod's family provider type is intentionally inferred; spelling it out
// would expose implementation-heavy generic names without improving call sites.
// ignore: specify_nonobvious_property_types
final allAppSitesForPersonProvider =
    FutureProvider.family<List<AppSite>, String>((ref, personId) async {
  final repo = ref.watch(appSiteRepositoryProvider);
  final active = await repo.listActiveForPerson(personId);
  final archived = await repo.listArchivedForPerson(personId);
  return [...active, ...archived];
});

void invalidateAppSitesState(WidgetRef ref) {
  ref
    ..invalidate(activeAppSitesProvider)
    ..invalidate(archivedAppSitesProvider)
    ..invalidate(allAppSitesForPersonProvider);
}
