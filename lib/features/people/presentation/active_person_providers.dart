import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/people/data/active_person_preference.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

/// The id of the currently-active Person on this device, or `null` if the
/// roster is empty.
///
/// Resolution logic (in [ActivePersonIdNotifier.build]):
///
/// 1. Read the last-chosen id from [ActivePersonPreference].
/// 2. If it still corresponds to a non-deleted Person, use it.
/// 3. Otherwise, fall back to the oldest Person in the roster and persist
///    that choice so subsequent reads are stable.
/// 4. If the roster is empty, return `null`.
///
/// Downstream UI never has to think about "stale id that refers to a
/// deleted Person" — that's reconciled here.
class ActivePersonIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final pref = ref.watch(activePersonPreferenceProvider);
    // Read the roster directly through the repository rather than watching
    // peopleListProvider.future. Riverpod 3's subscription accounting trips
    // an internal assertion when the same provider is watched via both
    // `.future` (here) and as an `AsyncValue` (in UI widgets) under certain
    // invalidation orderings; staying off that path keeps things simple.
    //
    // The price: mutations must explicitly invalidate this notifier too.
    // [invalidatePeopleState] below is the one place that happens.
    final repo = ref.watch(personRepositoryProvider);
    final people = await repo.listActive();

    final stored = await pref.getActivePersonId();
    if (stored != null && people.any((p) => p.id == stored)) {
      return stored;
    }
    if (people.isNotEmpty) {
      final fallback = people.first.id;
      await pref.setActivePersonId(fallback);
      return fallback;
    }
    await pref.setActivePersonId(null);
    return null;
  }

  /// Explicitly select a Person as the active one. Passing `null` clears
  /// the selection — callers should only do this when removing the last
  /// remaining Person; other flows should invalidate and let [build]
  /// re-resolve.
  Future<void> select(String? id) async {
    final pref = ref.read(activePersonPreferenceProvider);
    await pref.setActivePersonId(id);
    state = AsyncValue.data(id);
  }
}

final activePersonIdProvider =
    AsyncNotifierProvider<ActivePersonIdNotifier, String?>(
  ActivePersonIdNotifier.new,
);

/// The currently-active [Person], or `null` if the roster is empty or the
/// id points to a Person that no longer exists.
///
/// Combines [activePersonIdProvider] with a direct repository lookup —
/// deliberately not watching [peopleListProvider] here; see
/// [ActivePersonIdNotifier.build] for why.
final activePersonProvider = FutureProvider<Person?>((ref) async {
  final id = await ref.watch(activePersonIdProvider.future);
  if (id == null) return null;
  final repo = ref.watch(personRepositoryProvider);
  return repo.findById(id);
});

/// Refresh every provider that derives from "which People exist".
///
/// Must be called after any Create / Update / SoftDelete, so the list
/// screen, the banner, the switcher, and the active-person notifier all
/// resolve against the new state of the database.
void invalidatePeopleState(WidgetRef ref) {
  ref
    ..invalidate(peopleListProvider)
    ..invalidate(activePersonIdProvider)
    ..invalidate(activePersonProvider);
}
