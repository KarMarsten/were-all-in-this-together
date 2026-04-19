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

void invalidateAppSitesState(WidgetRef ref) {
  ref
    ..invalidate(activeAppSitesProvider)
    ..invalidate(archivedAppSitesProvider);
}
