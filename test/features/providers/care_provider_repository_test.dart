import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/providers/data/care_provider_repository.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late CareProviderRepository providers;

  // Ticking UTC clock — every call advances one millisecond so
  // updatedAt / deletedAt are strictly monotonic across operations.
  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2030).add(Duration(milliseconds: clockCallCount));
  }

  late String alexId;

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
    providers = CareProviderRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    final alex = await people.create(displayName: 'Alex');
    alexId = alex.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('create', () {
    test('returns a CareProvider with every provided field', () async {
      final prov = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
        specialty: 'Developmental pediatrics',
        phone: '+1 555-123-4567',
        address: '1 Elm St, Anytown',
        portalUrl: 'https://mychart.example.com',
        notes: 'Front desk: Ana',
      );

      expect(prov.id, isNotEmpty);
      expect(prov.personId, alexId);
      expect(prov.name, 'Dr. Chen');
      expect(prov.kind, CareProviderKind.pcp);
      expect(prov.specialty, 'Developmental pediatrics');
      expect(prov.phone, '+1 555-123-4567');
      expect(prov.address, '1 Elm St, Anytown');
      expect(prov.portalUrl, 'https://mychart.example.com');
      expect(prov.notes, 'Front desk: Ana');
      expect(prov.createdAt, prov.updatedAt);
      expect(prov.deletedAt, isNull);
      expect(prov.rowVersion, 1);
    });

    test('rejects a blank name', () async {
      expect(
        () => providers.create(
          personId: alexId,
          name: '   ',
          kind: CareProviderKind.other,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when the owning Person has no key on this device', () async {
      expect(
        () => providers.create(
          personId: 'no-such-person',
          name: 'Dr. Null',
          kind: CareProviderKind.other,
        ),
        throwsA(isA<CareProviderKeyMissingError>()),
      );
    });

    test('encrypted payload ciphertext does not leak name or specialty',
        () async {
      await providers.create(
        personId: alexId,
        name: 'Secret Name',
        kind: CareProviderKind.therapist,
        specialty: 'Confidential specialty',
      );

      final rows = await db.select(db.careProviders).get();
      expect(rows, hasLength(1));
      final raw = String.fromCharCodes(rows.single.payload);
      expect(raw, isNot(contains('Secret Name')));
      expect(raw, isNot(contains('Confidential specialty')));
    });
  });

  group('findById', () {
    test('returns the row when active', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );

      final found = await providers.findById(created.id);
      expect(found, isNotNull);
      expect(found!.id, created.id);
      expect(found.name, 'Dr. Chen');
    });

    test('returns the row even when archived (historical lookup)', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Past',
        kind: CareProviderKind.specialist,
      );
      await providers.archive(created.id);

      final found = await providers.findById(created.id);
      expect(found, isNotNull);
      expect(found!.deletedAt, isNotNull);
      expect(found.name, 'Dr. Past');
    });

    test('returns null for an unknown id', () async {
      expect(await providers.findById('not-a-real-id'), isNull);
    });
  });

  group('listActiveForPerson / listArchivedForPerson', () {
    test('separates active and archived rows per Person', () async {
      final beth = await people.create(displayName: 'Beth');

      final alexPcp = await providers.create(
        personId: alexId,
        name: 'Alex PCP',
        kind: CareProviderKind.pcp,
      );
      final alexOld = await providers.create(
        personId: alexId,
        name: 'Alex Old',
        kind: CareProviderKind.other,
      );
      final bethPcp = await providers.create(
        personId: beth.id,
        name: 'Beth PCP',
        kind: CareProviderKind.pcp,
      );

      await providers.archive(alexOld.id);

      final activeAlex = await providers.listActiveForPerson(alexId);
      expect(activeAlex.map((p) => p.id), [alexPcp.id]);

      final archivedAlex = await providers.listArchivedForPerson(alexId);
      expect(archivedAlex.map((p) => p.id), [alexOld.id]);

      final activeBeth = await providers.listActiveForPerson(beth.id);
      expect(activeBeth.map((p) => p.id), [bethPcp.id]);
    });

    test('listActiveForPerson orders oldest first', () async {
      final first = await providers.create(
        personId: alexId,
        name: 'First',
        kind: CareProviderKind.other,
      );
      final second = await providers.create(
        personId: alexId,
        name: 'Second',
        kind: CareProviderKind.other,
      );

      final list = await providers.listActiveForPerson(alexId);
      expect(list.map((p) => p.id), [first.id, second.id]);
    });

    test('skips rows whose Person key is missing', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Lost',
        kind: CareProviderKind.pcp,
      );
      await keys.delete(alexId);

      final list = await providers.listActiveForPerson(alexId);
      expect(list, isEmpty);
      expect(created.id, isNotEmpty);
    });
  });

  group('update', () {
    test('persists new values and bumps rowVersion', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );

      final updated = await providers.update(
        created.copyWith(
          name: 'Dr. Chen-Lopez',
          specialty: 'DBP',
          phone: '+1 555-000-0000',
        ),
      );
      expect(updated.name, 'Dr. Chen-Lopez');
      expect(updated.specialty, 'DBP');
      expect(updated.phone, '+1 555-000-0000');
      expect(updated.rowVersion, created.rowVersion + 1);

      final reloaded = await providers.findById(created.id);
      expect(reloaded!.name, 'Dr. Chen-Lopez');
      expect(reloaded.specialty, 'DBP');
      expect(reloaded.phone, '+1 555-000-0000');
    });

    test('refuses to change personId', () async {
      final beth = await people.create(displayName: 'Beth');
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );

      expect(
        () => providers.update(created.copyWith(personId: beth.id)),
        throwsA(isA<StateError>()),
      );
    });

    test('throws CareProviderNotFoundError on an unknown id', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );
      final phantom = created.copyWith(id: 'does-not-exist');

      expect(
        () => providers.update(phantom),
        throwsA(isA<CareProviderNotFoundError>()),
      );
    });
  });

  group('archive / restore', () {
    test('archive marks the row and hides it from listActive', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );

      await providers.archive(created.id);

      final active = await providers.listActiveForPerson(alexId);
      expect(active, isEmpty);
      final archived = await providers.listArchivedForPerson(alexId);
      expect(archived, hasLength(1));
      expect(archived.single.deletedAt, isNotNull);
    });

    test('a second archive throws because the row is no longer active',
        () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );
      await providers.archive(created.id);

      expect(
        () => providers.archive(created.id),
        throwsA(isA<CareProviderNotFoundError>()),
      );
    });

    test('restore returns an archived row to the active list', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );
      await providers.archive(created.id);

      await providers.restore(created.id);

      final active = await providers.listActiveForPerson(alexId);
      expect(active.map((p) => p.id), [created.id]);
      final archived = await providers.listArchivedForPerson(alexId);
      expect(archived, isEmpty);
    });

    test('restore on a non-archived row throws', () async {
      final created = await providers.create(
        personId: alexId,
        name: 'Dr. Chen',
        kind: CareProviderKind.pcp,
      );

      expect(
        () => providers.restore(created.id),
        throwsA(isA<CareProviderNotFoundError>()),
      );
    });
  });
}
