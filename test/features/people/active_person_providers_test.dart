import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/active_person_preference.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

import '../../helpers/in_memory_active_person_preference.dart';
import '../../helpers/in_memory_key_storage.dart';

ProviderContainer _makeContainer({String? initialActiveId}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      keyStorageProvider.overrideWith((_) => InMemoryKeyStorage()),
      activePersonPreferenceProvider.overrideWith(
        (_) => InMemoryActivePersonPreference(initialId: initialActiveId),
      ),
    ],
  );
}

void main() {
  group('ActivePersonIdNotifier', () {
    test('returns null when the roster is empty', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final id = await container.read(activePersonIdProvider.future);
      expect(id, isNull);
    });

    test(
      'auto-selects and persists the oldest Person when nothing has been '
      'chosen yet',
      () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final repo = container.read(personRepositoryProvider);
        final alex = await repo.create(displayName: 'Alex');
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await repo.create(displayName: 'Sam');

        final id = await container.read(activePersonIdProvider.future);
        expect(id, alex.id);

        // Persisted to the preference store for stability across reads.
        final pref = container.read(activePersonPreferenceProvider);
        expect(await pref.getActivePersonId(), alex.id);
      },
    );

    test('honours a previously-persisted id when it still exists', () async {
      // Bootstrap a roster and capture ids.
      final seed = _makeContainer();
      final seedRepo = seed.read(personRepositoryProvider);
      final _ = await seedRepo.create(displayName: 'Alex');
      final sam = await seedRepo.create(displayName: 'Sam');
      seed.dispose();

      // Fresh container with Sam pre-selected. We override the db with a
      // new in-memory one so we also need to re-create the people — this
      // test instead focuses on the preference-persisted case by using the
      // same container across reads.
      final container = _makeContainer(initialActiveId: sam.id);
      addTearDown(container.dispose);

      final repo = container.read(personRepositoryProvider);
      await repo.create(displayName: 'Alex');
      final reSam = await repo.create(displayName: 'Sam');
      // Poke the preference to point at the new Sam id.
      await container
          .read(activePersonPreferenceProvider)
          .setActivePersonId(reSam.id);
      container.invalidate(activePersonIdProvider);

      final id = await container.read(activePersonIdProvider.future);
      expect(id, reSam.id);
    });

    test(
      'falls back to the oldest Person when the persisted id no longer '
      'corresponds to a real Person',
      () async {
        final container = _makeContainer(
          initialActiveId: 'ghost-never-existed',
        );
        addTearDown(container.dispose);

        final repo = container.read(personRepositoryProvider);
        final alex = await repo.create(displayName: 'Alex');

        final id = await container.read(activePersonIdProvider.future);
        expect(id, alex.id);
      },
    );

    test('select() changes the active id and persists it', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final repo = container.read(personRepositoryProvider);
      final alex = await repo.create(displayName: 'Alex');
      final sam = await repo.create(displayName: 'Sam');

      await container.read(activePersonIdProvider.future);
      await container.read(activePersonIdProvider.notifier).select(sam.id);

      expect(
        await container.read(activePersonIdProvider.future),
        sam.id,
      );
      expect(
        await container
            .read(activePersonPreferenceProvider)
            .getActivePersonId(),
        sam.id,
      );
      // Alex is still in the roster — just not active.
      final ids = (await repo.listActive()).map((p) => p.id);
      expect(ids, containsAll([alex.id, sam.id]));
    });

    test(
      'after soft-deleting the active Person the notifier falls back to '
      'another Person',
      () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final repo = container.read(personRepositoryProvider);
        final alex = await repo.create(displayName: 'Alex');
        final sam = await repo.create(displayName: 'Sam');
        await container.read(activePersonIdProvider.future);
        await container.read(activePersonIdProvider.notifier).select(alex.id);

        await repo.softDelete(alex.id);
        // Notifier doesn't auto-rebuild off peopleListProvider (see
        // ActivePersonIdNotifier.build docs); invalidatePeopleState is the
        // helper the UI uses after mutations, but here we invalidate
        // activePersonIdProvider directly to isolate this test's concern.
        container.invalidate(activePersonIdProvider);

        final id = await container.read(activePersonIdProvider.future);
        expect(id, sam.id);
      },
    );
  });

  group('activePersonProvider', () {
    test('resolves to the Person whose id matches activePersonId', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final repo = container.read(personRepositoryProvider);
      final alex = await repo.create(
        displayName: 'Alex',
        pronouns: 'they/them',
      );

      final person = await container.read(activePersonProvider.future);
      expect(person?.id, alex.id);
      expect(person?.displayName, 'Alex');
      expect(person?.pronouns, 'they/them');
    });

    test('returns null when the roster is empty', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final person = await container.read(activePersonProvider.future);
      expect(person, isNull);
    });
  });
}
