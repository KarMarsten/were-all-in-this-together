import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late MedicationRepository meds;
  late DoseLogRepository logs;

  // Monotonic clock so updatedAt > createdAt on upsert.
  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2026).add(Duration(milliseconds: clockCallCount));
  }

  late String alexId;
  late String medId;
  final scheduledAt = DateTime.utc(2026, 4, 18, 8);

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
      events: MedicationEventRepository(
        database: db,
        crypto: crypto,
        keys: keys,
        clock: tickingClock,
      ),
    );
    logs = DoseLogRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );

    final alex = await people.create(displayName: 'Alex');
    alexId = alex.id;
    final med = await meds.create(
      personId: alexId,
      name: 'Methylphenidate',
      dose: '10mg',
    );
    medId = med.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('record', () {
    test('inserts a new log for a fresh (med, scheduledAt) pair', () async {
      final log = await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.taken,
      );

      expect(log.personId, alexId);
      expect(log.medicationId, medId);
      expect(log.scheduledAt, scheduledAt);
      expect(log.outcome, DoseOutcome.taken);
      expect(log.rowVersion, 1);
      expect(log.deletedAt, isNull);

      final row = await (db.select(db.doseLogs)
            ..where((l) => l.id.equals(log.id)))
          .getSingle();
      expect(
        row.scheduledAtUtcMs,
        scheduledAt.toUtc().millisecondsSinceEpoch,
      );
    });

    test('upserts on the same (medicationId, scheduledAt) pair', () async {
      final first = await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.taken,
        note: 'original',
      );
      final second = await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.skipped,
        note: 'changed my mind',
      );

      expect(second.id, first.id);
      expect(second.outcome, DoseOutcome.skipped);
      expect(second.note, 'changed my mind');
      expect(second.rowVersion, first.rowVersion + 1);

      // Only one DB row — no phantom duplicate.
      final count = await (db.selectOnly(db.doseLogs)
            ..addColumns([db.doseLogs.id.count()]))
          .map((r) => r.read(db.doseLogs.id.count())!)
          .getSingle();
      expect(count, 1);
    });

    test('whitespace-only note is stored as null', () async {
      final log = await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.taken,
        note: '   ',
      );
      expect(log.note, isNull);
    });

    test(
        'encrypts the payload — the raw DB blob does not contain the note '
        'as plaintext', () async {
      const secret = 'UniqueNoteTokenThatMustNotLeakToDisk';
      final log = await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.taken,
        note: secret,
      );
      final row = await (db.select(db.doseLogs)
            ..where((l) => l.id.equals(log.id)))
          .getSingle();
      expect(String.fromCharCodes(row.payload).contains(secret), isFalse);
    });

    test('unknown Person id throws DoseLogKeyMissingError', () async {
      await expectLater(
        () => logs.record(
          personId: 'not-a-real-person',
          medicationId: medId,
          scheduledAt: scheduledAt,
          outcome: DoseOutcome.taken,
        ),
        throwsA(isA<DoseLogKeyMissingError>()),
      );
    });

    test('re-record after undo resurrects the row (clears deletedAt)',
        () async {
      await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.taken,
      );
      await logs.undo(medicationId: medId, scheduledAt: scheduledAt);
      await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.skipped,
      );

      final row = await (db.select(db.doseLogs)
            ..where((l) => l.medicationId.equals(medId)))
          .getSingle();
      expect(row.deletedAt, isNull);
    });
  });

  group('undo', () {
    test('soft-deletes an existing log', () async {
      await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: scheduledAt,
        outcome: DoseOutcome.taken,
      );
      await logs.undo(medicationId: medId, scheduledAt: scheduledAt);

      final row = await (db.select(db.doseLogs)
            ..where((l) => l.medicationId.equals(medId)))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('is a no-op for a missing log', () async {
      await logs.undo(medicationId: medId, scheduledAt: scheduledAt);
      final count = await (db.selectOnly(db.doseLogs)
            ..addColumns([db.doseLogs.id.count()]))
          .map((r) => r.read(db.doseLogs.id.count())!)
          .getSingle();
      expect(count, 0);
    });
  });

  group('forMedicationsInRange', () {
    test('returns only non-tombstoned logs in the half-open range', () async {
      final morning = DateTime.utc(2026, 4, 18, 8);
      final evening = DateTime.utc(2026, 4, 18, 20);
      final tomorrow = DateTime.utc(2026, 4, 19, 8);

      await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: morning,
        outcome: DoseOutcome.taken,
      );
      await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: evening,
        outcome: DoseOutcome.skipped,
      );
      await logs.record(
        personId: alexId,
        medicationId: medId,
        scheduledAt: tomorrow,
        outcome: DoseOutcome.taken,
      );
      // Soft-delete the morning one; should not show up.
      await logs.undo(medicationId: medId, scheduledAt: morning);

      final result = await logs.forMedicationsInRange(
        medicationIds: [medId],
        fromInclusive: DateTime.utc(2026, 4, 18),
        toExclusive: DateTime.utc(2026, 4, 19),
      );

      expect(result, hasLength(1));
      expect(result.single.scheduledAt, evening);
    });

    test('empty medicationIds short-circuits', () async {
      final result = await logs.forMedicationsInRange(
        medicationIds: const <String>[],
        fromInclusive: DateTime.utc(2026, 4, 18),
        toExclusive: DateTime.utc(2026, 4, 19),
      );
      expect(result, isEmpty);
    });
  });
}
