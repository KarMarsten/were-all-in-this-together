import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_entry_repository.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';

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

/// Non-archived structured [ProfileEntry] rows for the active Person
/// (every [ProfileEntryStatus]), newest first. Use for Profile editing,
/// routine parent pickers, and status filters.
final profileEntriesForActivePersonProvider =
    FutureProvider<List<ProfileEntry>>((ref) async {
      final personId = await ref.watch(activePersonIdProvider.future);
      if (personId == null) return const [];
      final profileRepo = ref.watch(profileRepositoryProvider);
      final entriesRepo = ref.watch(profileEntryRepositoryProvider);
      final profile = await profileRepo.getOrCreateForPerson(personId);
      return entriesRepo.listForProfile(
        profileId: profile.id,
        personId: personId,
      );
    });

/// Active-status subset of [profileEntriesForActivePersonProvider]. Calm and
/// the default Profile list filter use this; Notes pickers use the full list.
final activeProfileLinesProvider = FutureProvider<List<ProfileEntry>>((
  ref,
) async {
  final all = await ref.watch(profileEntriesForActivePersonProvider.future);
  return all
      .where((e) => e.status == ProfileEntryStatus.active)
      .toList();
});

/// Call after saving profile fields so the feed re-fetches.
void invalidateProfileState(WidgetRef ref) {
  ref.invalidate(activePersonProfileProvider);
}

/// Call after saving or archiving profile entries.
void invalidateProfileEntriesState(WidgetRef ref) {
  ref
    ..invalidate(profileEntriesForActivePersonProvider)
    ..invalidate(activeProfileLinesProvider);
}
