import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_entry_repository.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late ProfileRepository profiles;
  late ProfileEntryRepository entries;

  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2040).add(Duration(milliseconds: clockCallCount));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
    clockCallCount = 0;
    people = PersonRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    profiles = ProfileRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    entries = ProfileEntryRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    await people.create(displayName: 'Riley');
  });

  tearDown(() async {
    await db.close();
  });

  group('create + listActiveForProfile', () {
    test('round-trips label and details', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);

      final created = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.trigger,
        label: ' Fluorescent lights ',
        details: '  Wear hat indoors.  ',
      );
      expect(created.label, 'Fluorescent lights');
      expect(created.details, '  Wear hat indoors.  ');

      final list = await entries.listActiveForProfile(
        profileId: profile.id,
        personId: person.id,
      );
      expect(list, hasLength(1));
      expect(list.single.section, ProfileEntrySection.trigger);
      expect(list.single.label, 'Fluorescent lights');
      expect(list.single.details, '  Wear hat indoors.  ');
    });
  });

  group('update', () {
    test('persists section and status', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final created = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.stim,
        label: 'Hand flapping',
      );

      final updated = await entries.update(
        created.copyWith(
          section: ProfileEntrySection.whatHelps,
          status: ProfileEntryStatus.paused,
          label: 'Hand flapping when excited',
        ),
      );
      expect(updated.rowVersion, created.rowVersion + 1);

      final again = await entries.findById(created.id);
      expect(again!.section, ProfileEntrySection.whatHelps);
      expect(again.status, ProfileEntryStatus.paused);
      expect(again.label, 'Hand flapping when excited');
    });
  });

  group('parent + routine steps', () {
    test('clears parent id for non–routine-step sections', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final block = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.routineBlock,
        label: 'Morning',
      );
      final created = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.stim,
        label: 'Hand tapping',
        parentEntryId: block.id,
      );
      expect(created.parentEntryId, isNull);
      final again = await entries.findById(created.id);
      expect(again!.parentEntryId, isNull);
    });

    test('routine step requires an active routine-block parent', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      expect(
        () => entries.create(
          profileId: profile.id,
          personId: person.id,
          section: ProfileEntrySection.routineStep,
          label: 'Brush teeth',
        ),
        throwsA(isA<ProfileEntryInvalidParentError>()),
      );
    });

    test('rejects parent that is not a routine block', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final stim = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.stim,
        label: 'Rocking',
      );
      expect(
        () => entries.create(
          profileId: profile.id,
          personId: person.id,
          section: ProfileEntrySection.routineStep,
          label: 'Step',
          parentEntryId: stim.id,
        ),
        throwsA(isA<ProfileEntryInvalidParentError>()),
      );
    });

    test('round-trips block → step link', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final block = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.routineBlock,
        label: 'Bedtime',
      );
      final step = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.routineStep,
        label: 'PJs on',
        parentEntryId: block.id,
      );
      expect(step.parentEntryId, block.id);
      final loaded = await entries.findById(step.id);
      expect(loaded!.parentEntryId, block.id);
    });

    test('update to non-step clears stored parent', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final block = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.routineBlock,
        label: 'School day',
      );
      final step = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.routineStep,
        label: 'Backpack',
        parentEntryId: block.id,
      );
      final updated = await entries.update(
        step.copyWith(
          section: ProfileEntrySection.other,
          label: 'Was a step',
        ),
      );
      expect(updated.parentEntryId, isNull);
      final again = await entries.findById(step.id);
      expect(again!.parentEntryId, isNull);
    });
  });

  group('firstNoted / lastNoted', () {
    test('rejects first noted after last noted', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final first = DateTime.utc(2025, 6, 10);
      final last = DateTime.utc(2025, 6);
      expect(
        () => entries.create(
          profileId: profile.id,
          personId: person.id,
          section: ProfileEntrySection.trigger,
          label: 'Crowds',
          firstNoted: first,
          lastNoted: last,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('round-trips noted dates', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final first = DateTime.utc(2024);
      final last = DateTime.utc(2024, 12);
      final created = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.earlySign,
        label: 'Pacing',
        firstNoted: first,
        lastNoted: last,
      );
      expect(created.firstNoted, first);
      expect(created.lastNoted, last);
      final again = await entries.findById(created.id);
      expect(again!.firstNoted, first);
      expect(again.lastNoted, last);
    });
  });

  group('archive + restore', () {
    test('drops from active list then returns', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final created = await entries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.other,
        label: 'Note',
      );

      await entries.archive(created.id);
      final active = await entries.listActiveForProfile(
        profileId: profile.id,
        personId: person.id,
      );
      expect(active, isEmpty);

      await entries.restore(created.id);
      final active2 = await entries.listActiveForProfile(
        profileId: profile.id,
        personId: person.id,
      );
      expect(active2, hasLength(1));
    });
  });
}
