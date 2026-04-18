import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late MedicationRepository meds;
  late MedicationGroupRepository groups;

  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2026).add(Duration(milliseconds: clockCallCount));
  }

  late String alexId;
  late String aspirinId;
  late String vitaminId;

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
    meds = MedicationRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    groups = MedicationGroupRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );

    final alex = await people.create(displayName: 'Alex');
    alexId = alex.id;
    aspirinId = (await meds.create(personId: alexId, name: 'Aspirin')).id;
    vitaminId = (await meds.create(personId: alexId, name: 'Vitamin D')).id;
  });

  tearDown(() async {
    await db.close();
  });

  group('create', () {
    test('persists the group and returns the hydrated object', () async {
      final g = await groups.create(
        personId: alexId,
        name: 'Morning stack',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        memberMedicationIds: [aspirinId, vitaminId],
      );

      expect(g.personId, alexId);
      expect(g.name, 'Morning stack');
      expect(g.schedule.kind, ScheduleKind.daily);
      expect(g.memberMedicationIds, [aspirinId, vitaminId]);
      expect(g.deletedAt, isNull);
      expect(g.rowVersion, 1);
    });

    test('dedupes and drops empty member ids', () async {
      final g = await groups.create(
        personId: alexId,
        name: 'Stack',
        memberMedicationIds: [
          aspirinId,
          ' ',
          aspirinId,
          vitaminId,
          '',
        ],
      );
      expect(g.memberMedicationIds, [aspirinId, vitaminId]);
    });

    test('refuses an empty name', () async {
      expect(
        () => groups.create(personId: alexId, name: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws MedicationGroupKeyMissingError when the key is absent',
        () async {
      await keys.delete(alexId);
      expect(
        () => groups.create(personId: alexId, name: 'Stack'),
        throwsA(isA<MedicationGroupKeyMissingError>()),
      );
    });

    test('the raw DB blob does not contain the name in plaintext', () async {
      const secretName = 'HighlyDistinctiveStackName_Xylophone7';
      final g = await groups.create(personId: alexId, name: secretName);
      final row = await (db.select(db.medicationGroups)
            ..where((r) => r.id.equals(g.id)))
          .getSingle();
      expect(String.fromCharCodes(row.payload).contains(secretName), isFalse);
    });
  });

  group('list / findById', () {
    test('listActiveForPerson skips archived rows and sorts by createdAt',
        () async {
      final a = await groups.create(personId: alexId, name: 'A');
      await groups.create(personId: alexId, name: 'B');
      await groups.archive(a.id);

      final active = await groups.listActiveForPerson(alexId);
      expect(active.map((g) => g.name).toList(), ['B']);
    });

    test('listArchivedForPerson returns only archived rows, newest first',
        () async {
      final a = await groups.create(personId: alexId, name: 'A');
      final b = await groups.create(personId: alexId, name: 'B');
      await groups.archive(a.id);
      await groups.archive(b.id);

      final archived = await groups.listArchivedForPerson(alexId);
      expect(archived.first.name, 'B');
      expect(archived.length, 2);
    });

    test('findById returns null for unknown and for archived rows', () async {
      final a = await groups.create(personId: alexId, name: 'A');
      await groups.archive(a.id);
      expect(await groups.findById(a.id), isNull);
      expect(await groups.findById('no-such-id'), isNull);
    });
  });

  group('update', () {
    test('updates fields, bumps rowVersion, preserves id', () async {
      final g = await groups.create(
        personId: alexId,
        name: 'Stack',
        memberMedicationIds: [aspirinId],
      );
      final updated = await groups.update(
        g.copyWith(
          name: 'Morning stack',
          memberMedicationIds: [aspirinId, vitaminId],
        ),
      );
      expect(updated.id, g.id);
      expect(updated.name, 'Morning stack');
      expect(updated.memberMedicationIds, [aspirinId, vitaminId]);
      expect(updated.rowVersion, g.rowVersion + 1);
    });

    test('refuses to change personId (ownership transfer)', () async {
      final other = await people.create(displayName: 'Kit');
      final g = await groups.create(personId: alexId, name: 'Stack');
      expect(
        () => groups.update(g.copyWith(personId: other.id)),
        throwsA(isA<StateError>()),
      );
    });

    test('throws MedicationGroupNotFoundError for an unknown id', () async {
      final g = await groups.create(personId: alexId, name: 'Stack');
      await groups.archive(g.id);
      // Delete the row entirely to simulate "unknown id".
      await (db.delete(db.medicationGroups)..where((r) => r.id.equals(g.id)))
          .go();
      expect(
        () => groups.update(g.copyWith(name: 'x')),
        throwsA(isA<MedicationGroupNotFoundError>()),
      );
    });
  });

  group('archive / restore', () {
    test('archive then restore round-trips cleanly', () async {
      final g = await groups.create(personId: alexId, name: 'Stack');
      await groups.archive(g.id);
      expect(await groups.findById(g.id), isNull);

      await groups.restore(g.id);
      final hydrated = await groups.findById(g.id);
      expect(hydrated, isNotNull);
      expect(hydrated!.deletedAt, isNull);
    });

    test('archive twice throws MedicationGroupNotFoundError', () async {
      final g = await groups.create(personId: alexId, name: 'Stack');
      await groups.archive(g.id);
      expect(
        () => groups.archive(g.id),
        throwsA(isA<MedicationGroupNotFoundError>()),
      );
    });

    test('restore on an active row throws MedicationGroupNotFoundError',
        () async {
      final g = await groups.create(personId: alexId, name: 'Stack');
      expect(
        () => groups.restore(g.id),
        throwsA(isA<MedicationGroupNotFoundError>()),
      );
    });
  });
}
