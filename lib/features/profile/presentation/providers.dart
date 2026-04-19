import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';

/// The [Profile] for the currently-active Person, creating an empty
/// row on first open.
///
/// Returns `null` when no Person is active — the screen shows an
/// "add someone first" prompt, matching other per-Person domains.
final activePersonProfileProvider = FutureProvider<Profile?>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getOrCreateForPerson(personId);
});

/// Call after saving profile fields so the feed re-fetches.
void invalidateProfileState(WidgetRef ref) {
  ref.invalidate(activePersonProfileProvider);
}
