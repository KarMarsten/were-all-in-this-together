import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';

/// The roster of non-deleted People, asynchronously resolved.
///
/// Screens consume this via `ref.watch(peopleListProvider)`. After any
/// mutation (create / update / soft-delete) callers should
/// `ref.invalidate(peopleListProvider)` so the UI re-fetches.
///
/// We deliberately don't yet offer a streaming provider — Phase 1 is a
/// single device with no background writers, so the roster can only change
/// as a result of an action the UI just performed, and explicit invalidate
/// gives us a cleaner mental model than wiring up a Drift stream.
final peopleListProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(personRepositoryProvider);
  return repo.listActive();
});
