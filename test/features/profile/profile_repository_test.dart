import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late ProfileRepository profiles;

  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2031).add(Duration(milliseconds: clockCallCount));
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
    await people.create(displayName: 'Alex');
  });

  tearDown(() async {
    await db.close();
  });

  group('getOrCreateForPerson', () {
    test('creates an empty profile on first call', () async {
      final alex = await people.listActive().then((l) => l.single);
      final p = await profiles.getOrCreateForPerson(alex.id);
      expect(p.personId, alex.id);
      expect(p.communicationNotes, isNull);
      expect(p.sleepBaseline, isNull);
      expect(p.appetiteBaseline, isNull);
    });

    test('returns the same row on second call', () async {
      final alex = await people.listActive().then((l) => l.single);
      final a = await profiles.getOrCreateForPerson(alex.id);
      final b = await profiles.getOrCreateForPerson(alex.id);
      expect(b.id, a.id);
    });
  });

  group('update', () {
    test('persists and round-trips narrative fields', () async {
      final alex = await people.listActive().then((l) => l.single);
      final created = await profiles.getOrCreateForPerson(alex.id);
      final updated = await profiles.update(
        created.copyWith(
          communicationNotes: 'Prefer text, no phone calls after 6pm.',
          sleepBaseline: 'Usually asleep by 22:00.',
          appetiteBaseline: 'Texture-sensitive; keep crackers on hand.',
        ),
      );
      expect(updated.rowVersion, created.rowVersion + 1);

      final again = await profiles.getOrCreateForPerson(alex.id);
      expect(
        again.communicationNotes,
        'Prefer text, no phone calls after 6pm.',
      );
      expect(again.sleepBaseline, 'Usually asleep by 22:00.');
      expect(
        again.appetiteBaseline,
        'Texture-sensitive; keep crackers on hand.',
      );
    });
  });
}
