import 'package:cryptography/cryptography.dart';
// `hide` so drift's isNull/isNotNull column builders don't collide with
// matcher's isNull/isNotNull matchers below.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late MedicationRepository meds;

  // Ticking UTC clock — every call advances one millisecond so
  // updatedAt / deletedAt are strictly monotonic across operations.
  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2030).add(Duration(milliseconds: clockCallCount));
  }

  /// Every test needs at least one Person with a registered key in order
  /// to create meds, so we seed one eagerly in setUp.
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
    meds = MedicationRepository(
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
    test('returns a Medication with the provided fields and a fresh id',
        () async {
      final med = await meds.create(
        personId: alexId,
        name: 'Methylphenidate',
        dose: '10mg',
        form: MedicationForm.pill,
        prescriber: 'Dr. Chen',
        notes: 'Take with food',
        startDate: DateTime.utc(2031, 1, 5),
      );

      expect(med.id, isNotEmpty);
      expect(med.personId, alexId);
      expect(med.name, 'Methylphenidate');
      expect(med.dose, '10mg');
      expect(med.form, MedicationForm.pill);
      expect(med.prescriber, 'Dr. Chen');
      expect(med.notes, 'Take with food');
      expect(med.startDate, DateTime.utc(2031, 1, 5));
      expect(med.endDate, isNull);
      expect(med.rowVersion, 1);
      expect(med.keyVersion, 1);
      expect(med.deletedAt, isNull);
      expect(med.createdAt, med.updatedAt);
    });

    test(
        'encrypts the payload — the raw DB blob does not contain the med '
        'name as plaintext', () async {
      final med = await meds.create(
        personId: alexId,
        name: 'VerySpecificMedicationToken',
      );
      final row = await (db.select(db.medications)
            ..where((m) => m.id.equals(med.id)))
          .getSingle();

      final asString = String.fromCharCodes(row.payload);
      expect(asString.contains('VerySpecificMedicationToken'), isFalse);
    });

    test('rejects an empty name', () async {
      await expectLater(
        () => meds.create(personId: alexId, name: '   '),
        throwsArgumentError,
      );
    });

    test('throws MedicationKeyMissingError for an unknown Person id',
        () async {
      await expectLater(
        () => meds.create(personId: 'not-a-real-person', name: 'Ibuprofen'),
        throwsA(isA<MedicationKeyMissingError>()),
      );
    });

    test(
        'two creates produce distinct ids and distinct ciphertexts even '
        'at identical plaintext', () async {
      final a = await meds.create(personId: alexId, name: 'Twin');
      final b = await meds.create(personId: alexId, name: 'Twin');

      expect(a.id, isNot(equals(b.id)));

      final rowA = await (db.select(db.medications)
            ..where((m) => m.id.equals(a.id)))
          .getSingle();
      final rowB = await (db.select(db.medications)
            ..where((m) => m.id.equals(b.id)))
          .getSingle();

      expect(rowA.payload, isNot(equals(rowB.payload)));
      final envA = EncryptedPayload.fromBytes(rowA.payload);
      final envB = EncryptedPayload.fromBytes(rowB.payload);
      expect(envA.nonce, isNot(equals(envB.nonce)));
    });
  });

  group('findById', () {
    test('round-trips every field', () async {
      final created = await meds.create(
        personId: alexId,
        name: 'Methylphenidate',
        dose: '10mg',
        form: MedicationForm.pill,
        prescriber: 'Dr. Chen',
        notes: 'With food',
        startDate: DateTime.utc(2031, 1, 5),
        endDate: DateTime.utc(2031, 6, 5),
      );

      final loaded = await meds.findById(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, created.id);
      expect(loaded.personId, alexId);
      expect(loaded.name, 'Methylphenidate');
      expect(loaded.dose, '10mg');
      expect(loaded.form, MedicationForm.pill);
      expect(loaded.prescriber, 'Dr. Chen');
      expect(loaded.notes, 'With food');
      expect(loaded.startDate, DateTime.utc(2031, 1, 5));
      expect(loaded.endDate, DateTime.utc(2031, 6, 5));
      expect(loaded.createdAt, created.createdAt);
      expect(loaded.updatedAt, created.updatedAt);
      expect(loaded.rowVersion, 1);
    });

    test('returns null for an unknown id', () async {
      expect(await meds.findById('not-a-real-id'), isNull);
    });

    test('returns null for an archived medication', () async {
      final created = await meds.create(personId: alexId, name: 'Ibuprofen');
      await meds.archive(created.id);
      expect(await meds.findById(created.id), isNull);
    });

    test(
        'throws MedicationKeyMissingError when the row exists but the '
        "Person's key is gone", () async {
      final created = await meds.create(personId: alexId, name: 'Ibuprofen');
      await keys.delete(alexId);

      await expectLater(
        () => meds.findById(created.id),
        throwsA(isA<MedicationKeyMissingError>()),
      );
    });

    test(
        'rejects payloads whose AAD has been tampered — i.e. a ciphertext '
        'relocated between rows of the same Person', () async {
      final a = await meds.create(personId: alexId, name: 'Alpha');
      final b = await meds.create(personId: alexId, name: 'Beta');

      // Copy B's payload into A's row. Both blobs are individually
      // authentic under Alex's key; AAD binding to the *med id* is what
      // exposes the swap.
      final bRow = await (db.select(db.medications)
            ..where((m) => m.id.equals(b.id)))
          .getSingle();
      await (db.update(db.medications)..where((m) => m.id.equals(a.id)))
          .write(MedicationsCompanion(payload: Value(bRow.payload)));

      await expectLater(
        () => meds.findById(a.id),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test(
        'rejects payloads whose AAD is tampered across Persons — i.e. a '
        "blob moved from one Person's row to another's", () async {
      // Create a second Person so we have a cross-Person swap to attempt.
      final sam = await people.create(displayName: 'Sam');
      final alexMed = await meds.create(personId: alexId, name: 'Alpha');
      final samMed = await meds.create(personId: sam.id, name: 'Beta');

      // Copy Sam's payload into Alex's row and give Alex Sam's key so
      // the plaintext would decrypt if AAD were not bound to personId.
      final samRow = await (db.select(db.medications)
            ..where((m) => m.id.equals(samMed.id)))
          .getSingle();
      final samKey = await keys.load(sam.id);
      await keys.store(alexId, samKey!);
      await (db.update(db.medications)..where((m) => m.id.equals(alexMed.id)))
          .write(MedicationsCompanion(payload: Value(samRow.payload)));

      await expectLater(
        () => meds.findById(alexMed.id),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  group('listActiveForPerson', () {
    test('returns an empty list when the Person has no meds', () async {
      expect(await meds.listActiveForPerson(alexId), isEmpty);
    });

    test('returns only meds for the given Person, oldest first', () async {
      final sam = await people.create(displayName: 'Sam');
      final a = await meds.create(personId: alexId, name: 'Alpha');
      await meds.create(personId: sam.id, name: 'Sam-only');
      final c = await meds.create(personId: alexId, name: 'Gamma');

      final list = await meds.listActiveForPerson(alexId);
      expect(list.map((m) => m.id), [a.id, c.id]);
      expect(list.every((m) => m.personId == alexId), isTrue);
    });

    test('skips archived meds', () async {
      final a = await meds.create(personId: alexId, name: 'Alpha');
      final b = await meds.create(personId: alexId, name: 'Beta');
      await meds.archive(a.id);

      final list = await meds.listActiveForPerson(alexId);
      expect(list.map((m) => m.id), [b.id]);
    });

    test(
        'skips rows whose key is missing and returns the rest',
        () async {
      final sam = await people.create(displayName: 'Sam');
      await meds.create(personId: alexId, name: 'Alex-med');
      final samMed = await meds.create(personId: sam.id, name: 'Sam-med');

      // Wipe Alex's key; Alex's med row should be silently skipped when
      // listing Alex's meds, but Sam's unaffected list should still work.
      await keys.delete(alexId);
      expect(await meds.listActiveForPerson(alexId), isEmpty);
      final samList = await meds.listActiveForPerson(sam.id);
      expect(samList.map((m) => m.id), [samMed.id]);
    });
  });

  group('listArchivedForPerson', () {
    test('returns archived meds, most-recently-archived first', () async {
      final a = await meds.create(personId: alexId, name: 'Alpha');
      final b = await meds.create(personId: alexId, name: 'Beta');
      final c = await meds.create(personId: alexId, name: 'Gamma');

      await meds.archive(a.id); // archived first
      await meds.archive(c.id); // archived last

      final archived = await meds.listArchivedForPerson(alexId);
      expect(archived.map((m) => m.id), [c.id, a.id]);

      final active = await meds.listActiveForPerson(alexId);
      expect(active.map((m) => m.id), [b.id]);
    });
  });

  group('update', () {
    test('persists new fields, bumps rowVersion + updatedAt', () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      final updated = await meds.update(
        created.copyWith(
          name: 'Alpha v2',
          dose: '20mg',
          form: MedicationForm.liquid,
        ),
      );

      expect(updated.name, 'Alpha v2');
      expect(updated.dose, '20mg');
      expect(updated.form, MedicationForm.liquid);
      expect(updated.rowVersion, 2);
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);

      final reloaded = await meds.findById(created.id);
      expect(reloaded!.name, 'Alpha v2');
      expect(reloaded.dose, '20mg');
      expect(reloaded.form, MedicationForm.liquid);
      expect(reloaded.rowVersion, 2);
    });

    test('leaves createdAt untouched', () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      final updated = await meds.update(
        created.copyWith(name: 'Alpha v2'),
      );
      expect(updated.createdAt, created.createdAt);
    });

    test('throws MedicationNotFoundError for a non-existent row', () async {
      final ghost = Medication(
        id: 'not-a-real-id',
        personId: alexId,
        name: 'Nope',
        createdAt: DateTime.utc(2030),
        updatedAt: DateTime.utc(2030),
      );

      await expectLater(
        () => meds.update(ghost),
        throwsA(isA<MedicationNotFoundError>()),
      );
    });

    test(
        'throws MedicationKeyMissingError when the Person key is gone',
        () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      await keys.delete(alexId);

      await expectLater(
        () => meds.update(created.copyWith(name: 'New')),
        throwsA(isA<MedicationKeyMissingError>()),
      );
    });

    test('refuses to change ownership between Persons', () async {
      final sam = await people.create(displayName: 'Sam');
      final created = await meds.create(personId: alexId, name: 'Alpha');

      await expectLater(
        () => meds.update(created.copyWith(personId: sam.id)),
        throwsStateError,
      );
    });
  });

  group('archive / restore', () {
    test('archive sets deletedAt and hides the med from findById', () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      await meds.archive(created.id);

      expect(await meds.findById(created.id), isNull);

      final row = await (db.select(db.medications)
            ..where((m) => m.id.equals(created.id)))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('archive throws for an unknown id', () async {
      await expectLater(
        () => meds.archive('not-a-real-id'),
        throwsA(isA<MedicationNotFoundError>()),
      );
    });

    test('archive on an already-archived med throws', () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      await meds.archive(created.id);
      await expectLater(
        () => meds.archive(created.id),
        throwsA(isA<MedicationNotFoundError>()),
      );
    });

    test('restore clears deletedAt and makes the med findable again',
        () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      await meds.archive(created.id);
      await meds.restore(created.id);

      final reloaded = await meds.findById(created.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.deletedAt, isNull);
    });

    test('restore throws for a non-archived med', () async {
      final created = await meds.create(personId: alexId, name: 'Alpha');
      await expectLater(
        () => meds.restore(created.id),
        throwsA(isA<MedicationNotFoundError>()),
      );
    });
  });

  group('schedule', () {
    test('defaults to asNeeded when not supplied on create', () async {
      final created = await meds.create(personId: alexId, name: 'Ibuprofen');
      expect(created.schedule, MedicationSchedule.asNeeded);

      final reloaded = await meds.findById(created.id);
      expect(reloaded!.schedule, MedicationSchedule.asNeeded);
    });

    test('daily + times round-trips through the encrypted payload',
        () async {
      const schedule = MedicationSchedule(
        kind: ScheduleKind.daily,
        times: [
          ScheduledTime(hour: 8, minute: 0),
          ScheduledTime(hour: 20, minute: 30),
        ],
      );
      final created = await meds.create(
        personId: alexId,
        name: 'Omeprazole',
        schedule: schedule,
      );

      final reloaded = await meds.findById(created.id);
      expect(reloaded!.schedule.kind, ScheduleKind.daily);
      expect(reloaded.schedule.times, schedule.times);
      expect(reloaded.schedule.days, isEmpty);
    });

    test('weekly + days round-trips and preserves the day set', () async {
      const schedule = MedicationSchedule(
        kind: ScheduleKind.weekly,
        times: [ScheduledTime(hour: 9, minute: 0)],
        days: {1, 3, 5},
      );
      final created = await meds.create(
        personId: alexId,
        name: 'Methotrexate',
        schedule: schedule,
      );

      final reloaded = await meds.findById(created.id);
      expect(reloaded!.schedule.kind, ScheduleKind.weekly);
      expect(reloaded.schedule.days, {1, 3, 5});
    });

    test('update rewrites the schedule and bumps rowVersion', () async {
      final created = await meds.create(personId: alexId, name: 'Vitamin D');
      expect(created.schedule, MedicationSchedule.asNeeded);

      final updated = await meds.update(
        created.copyWith(
          schedule: const MedicationSchedule(
            kind: ScheduleKind.daily,
            times: [ScheduledTime(hour: 7, minute: 30)],
          ),
        ),
      );
      expect(updated.rowVersion, 2);

      final reloaded = await meds.findById(created.id);
      expect(reloaded!.schedule.kind, ScheduleKind.daily);
      expect(
        reloaded.schedule.times,
        const [ScheduledTime(hour: 7, minute: 30)],
      );
    });
  });
}
