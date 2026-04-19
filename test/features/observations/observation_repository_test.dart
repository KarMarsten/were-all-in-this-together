import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/observations/data/observation_repository.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';
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
  late ProfileEntryRepository profileEntries;
  late ObservationRepository observations;

  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2050).add(Duration(milliseconds: clockCallCount));
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
    profileEntries = ProfileEntryRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    observations = ObservationRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    await people.create(displayName: 'Jordan');
  });

  tearDown(() async {
    await db.close();
  });

  group('create + list', () {
    test('round-trips label, notes, tags, and profile link', () async {
      final person = await people.listActive().then((l) => l.single);
      final profile = await profiles.getOrCreateForPerson(person.id);
      final entry = await profileEntries.create(
        profileId: profile.id,
        personId: person.id,
        section: ProfileEntrySection.whatHelps,
        label: 'Weighted blanket',
      );
      final when = DateTime.utc(2025, 3, 15, 14, 30);
      final created = await observations.create(
        personId: person.id,
        observedAt: when,
        category: ObservationCategory.sensory,
        label: ' Quieter after blanket ',
        notes: ' 20 minutes on couch. ',
        tags: const ['home', 'evening', 'home'],
        profileEntryId: entry.id,
      );
      expect(created.label, 'Quieter after blanket');
      expect(created.notes, ' 20 minutes on couch. ');
      expect(created.tags, ['home', 'evening']);
      expect(created.profileEntryId, entry.id);

      final list = await observations.listActiveForPerson(person.id);
      expect(list, hasLength(1));
      expect(list.single.observedAt, when);
      expect(list.single.category, ObservationCategory.sensory);
    });
  });

  group('profile link validation', () {
    test('rejects unknown profile entry id', () async {
      final person = await people.listActive().then((l) => l.single);
      expect(
        () => observations.create(
          personId: person.id,
          observedAt: DateTime.utc(2025),
          category: ObservationCategory.general,
          label: 'x',
          profileEntryId: 'not-a-real-id',
        ),
        throwsA(isA<ObservationInvalidProfileEntryError>()),
      );
    });
  });

  group('archive + restore', () {
    test('drops from active list then returns', () async {
      final person = await people.listActive().then((l) => l.single);
      final n = await observations.create(
        personId: person.id,
        observedAt: DateTime.utc(2025, 5),
        category: ObservationCategory.general,
        label: 'Quick jot',
      );
      await observations.archive(n.id);
      expect(await observations.listActiveForPerson(person.id), isEmpty);
      await observations.restore(n.id);
      expect(await observations.listActiveForPerson(person.id), hasLength(1));
    });
  });
}
