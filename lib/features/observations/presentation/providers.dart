import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/observations/data/observation_repository.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

/// Active notes for the focused Person, newest `observedAt` first.
final activeObservationsProvider = FutureProvider<List<Observation>>((
  ref,
) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Observation>[];
  final repo = ref.watch(observationRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

/// Archived notes for the active Person, newest-archived first.
final archivedObservationsProvider = FutureProvider<List<Observation>>((
  ref,
) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Observation>[];
  final repo = ref.watch(observationRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

void invalidateObservationsState(WidgetRef ref) {
  ref
    ..invalidate(activeObservationsProvider)
    ..invalidate(archivedObservationsProvider);
}
