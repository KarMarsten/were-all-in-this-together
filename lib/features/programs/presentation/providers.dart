import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/programs/data/program_repository.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';

final activeProgramsProvider = FutureProvider<List<Program>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Program>[];
  final repo = ref.watch(programRepositoryProvider);
  return repo.listActiveForPerson(personId);
});

final archivedProgramsProvider = FutureProvider<List<Program>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Program>[];
  final repo = ref.watch(programRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

void invalidateProgramsState(WidgetRef ref) {
  ref
    ..invalidate(activeProgramsProvider)
    ..invalidate(archivedProgramsProvider);
}
