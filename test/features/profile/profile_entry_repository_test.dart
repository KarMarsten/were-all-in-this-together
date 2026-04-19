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
