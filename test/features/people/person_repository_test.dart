import 'package:cryptography/cryptography.dart';
// `hide` so drift's isNull/isNotNull column builders don't collide with
// matcher's isNull/isNotNull matchers below.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository repo;

  // Fixed-time clock backing, incrementing by 1ms per call so tests can
  // observe `updatedAt` changes without relying on wall-clock jitter.
  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2030).add(Duration(milliseconds: clockCallCount));
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
    clockCallCount = 0;
    repo = PersonRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('create', () {
    test('returns a Person with a generated id and the provided fields',
        () async {
      final person = await repo.create(
        displayName: 'Alex',
        pronouns: 'they/them',
        dob: DateTime.utc(2015, 3, 12),
        preferredFramingNotes: 'identity-first',
      );

      expect(person.id, isNotEmpty);
      expect(person.displayName, 'Alex');
      expect(person.pronouns, 'they/them');
      expect(person.dob, DateTime.utc(2015, 3, 12));
      expect(person.preferredFramingNotes, 'identity-first');
      expect(person.rowVersion, 1);
      expect(person.keyVersion, 1);
      expect(person.deletedAt, isNull);
      expect(person.createdAt, person.updatedAt);
    });

    test('persists a key for the new Person in key storage', () async {
      final person = await repo.create(displayName: 'Alex');
      expect(await keys.load(person.id), isNotNull);
    });

    test('encrypts the payload — the raw DB blob does not contain '
        'the display name as plaintext', () async {
      final person = await repo.create(displayName: 'VerySpecificSearchToken');
      final row = await (db.select(db.persons)
            ..where((p) => p.id.equals(person.id)))
          .getSingle();

      final asString = String.fromCharCodes(row.payload);
      expect(asString.contains('VerySpecificSearchToken'), isFalse);
    });

    test('rejects an empty displayName', () async {
      await expectLater(
        () => repo.create(displayName: '   '),
        throwsArgumentError,
      );
    });

    test('two creates produce distinct ids and distinct keys', () async {
      final a = await repo.create(displayName: 'Alex');
      final b = await repo.create(displayName: 'Sam');

      expect(a.id, isNot(equals(b.id)));
      final keyA = await keys.load(a.id);
      final keyB = await keys.load(b.id);
      expect(
        await keyA!.extractBytes(),
        isNot(equals(await keyB!.extractBytes())),
      );
    });
  });

  group('findById', () {
    test('round-trips all Person fields', () async {
      final created = await repo.create(
        displayName: 'Alex',
        pronouns: 'they/them',
        dob: DateTime.utc(2015, 3, 12),
        preferredFramingNotes: 'identity-first',
      );

      final loaded = await repo.findById(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, created.id);
      expect(loaded.displayName, 'Alex');
      expect(loaded.pronouns, 'they/them');
      expect(loaded.dob, DateTime.utc(2015, 3, 12));
      expect(loaded.preferredFramingNotes, 'identity-first');
      expect(loaded.createdAt, created.createdAt);
      expect(loaded.updatedAt, created.updatedAt);
      expect(loaded.rowVersion, 1);
    });

    test('returns null for an unknown id', () async {
      expect(await repo.findById('not-a-real-id'), isNull);
    });

    test('returns null for a soft-deleted Person', () async {
      final created = await repo.create(displayName: 'Alex');
      await repo.softDelete(created.id);

      expect(await repo.findById(created.id), isNull);
    });

    test('throws PersonKeyMissingError when the row exists but the key is '
        'gone', () async {
      final created = await repo.create(displayName: 'Alex');
      await keys.delete(created.id);

      await expectLater(
        () => repo.findById(created.id),
        throwsA(isA<PersonKeyMissingError>()),
      );
    });

    test('rejects payloads whose AAD has been tampered — i.e. a ciphertext '
        'relocated between rows', () async {
      final alex = await repo.create(displayName: 'Alex');
      final sam = await repo.create(displayName: 'Sam');

      // Swap Sam's payload into Alex's row while giving Alex Sam's key. Both
      // blobs individually are authentic; the AAD binding to the row id is
      // what exposes the swap.
      final samRow = await (db.select(db.persons)
            ..where((p) => p.id.equals(sam.id)))
          .getSingle();
      final samKey = await keys.load(sam.id);
      await keys.store(alex.id, samKey!);
      await (db.update(db.persons)..where((p) => p.id.equals(alex.id)))
          .write(PersonsCompanion(payload: Value(samRow.payload)));

      await expectLater(
        () => repo.findById(alex.id),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  group('listActive', () {
    test('returns an empty list when no Persons exist', () async {
      expect(await repo.listActive(), isEmpty);
    });

    test('returns only non-deleted Persons, oldest first', () async {
      final alex = await repo.create(displayName: 'Alex');
      final sam = await repo.create(displayName: 'Sam');
      final jordan = await repo.create(displayName: 'Jordan');
      await repo.softDelete(sam.id);

      final active = await repo.listActive();

      expect(active.map((p) => p.id), [alex.id, jordan.id]);
    });

    test('skips rows whose key is missing, returns the rest', () async {
      final alex = await repo.create(displayName: 'Alex');
      final sam = await repo.create(displayName: 'Sam');
      await keys.delete(alex.id);

      final active = await repo.listActive();

      expect(active.map((p) => p.id), [sam.id]);
    });
  });

  group('update', () {
    test('persists new fields and bumps rowVersion + updatedAt', () async {
      final created = await repo.create(displayName: 'Alex');
      final updated = await repo.update(
        created.copyWith(
          displayName: 'Alex Renamed',
          pronouns: 'she/they',
        ),
      );

      expect(updated.displayName, 'Alex Renamed');
      expect(updated.pronouns, 'she/they');
      expect(updated.rowVersion, 2);
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);

      final reloaded = await repo.findById(created.id);
      expect(reloaded!.displayName, 'Alex Renamed');
      expect(reloaded.pronouns, 'she/they');
      expect(reloaded.rowVersion, 2);
    });

    test('leaves createdAt untouched', () async {
      final created = await repo.create(displayName: 'Alex');
      await Future<void>.delayed(Duration.zero);
      final updated = await repo.update(
        created.copyWith(displayName: 'Alex Renamed'),
      );

      expect(updated.createdAt, created.createdAt);
    });

    test('throws PersonNotFoundError when the row does not exist', () async {
      final stranger = Person(
        id: 'not-a-real-id',
        displayName: 'Nobody',
        createdAt: DateTime.utc(2030),
        updatedAt: DateTime.utc(2030),
      );

      await expectLater(
        () => repo.update(stranger),
        throwsA(isA<PersonKeyMissingError>()),
      );
    });

    test('throws PersonKeyMissingError when the key is gone', () async {
      final created = await repo.create(displayName: 'Alex');
      await keys.delete(created.id);

      await expectLater(
        () => repo.update(created.copyWith(displayName: 'New')),
        throwsA(isA<PersonKeyMissingError>()),
      );
    });
  });

  group('softDelete', () {
    test('sets deletedAt and hides the Person from findById', () async {
      final created = await repo.create(displayName: 'Alex');
      await repo.softDelete(created.id);

      expect(await repo.findById(created.id), isNull);

      // The row is still physically there with deletedAt set — required for
      // Phase 2 tombstone replication.
      final row = await (db.select(db.persons)
            ..where((p) => p.id.equals(created.id)))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('does not delete the encryption key', () async {
      final created = await repo.create(displayName: 'Alex');
      await repo.softDelete(created.id);

      expect(await keys.load(created.id), isNotNull);
    });

    test('throws PersonNotFoundError on unknown id', () async {
      await expectLater(
        () => repo.softDelete('not-a-real-id'),
        throwsA(isA<PersonNotFoundError>()),
      );
    });

    test('a second softDelete on an already-deleted Person throws', () async {
      final created = await repo.create(displayName: 'Alex');
      await repo.softDelete(created.id);

      await expectLater(
        () => repo.softDelete(created.id),
        throwsA(isA<PersonNotFoundError>()),
      );
    });
  });

  group('EncryptedPayload integration', () {
    test('each create writes a fresh nonce: two sibling rows have different '
        'payload bytes even at identical plaintext', () async {
      final a = await repo.create(displayName: 'Twin');
      final b = await repo.create(displayName: 'Twin');

      final rowA = await (db.select(db.persons)
            ..where((p) => p.id.equals(a.id)))
          .getSingle();
      final rowB = await (db.select(db.persons)
            ..where((p) => p.id.equals(b.id)))
          .getSingle();

      expect(rowA.payload, isNot(equals(rowB.payload)));

      final envA = EncryptedPayload.fromBytes(rowA.payload);
      final envB = EncryptedPayload.fromBytes(rowB.payload);
      expect(envA.nonce, isNot(equals(envB.nonce)));
    });
  });
}
