import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

/// Direct unit tests for `MedicationEventRepository`. These exercise
/// the repo in isolation (no `MedicationRepository` driving it) so
/// the persistence / encryption / ordering contracts stay pinned
/// independently of the auto-log wiring.
void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late MedicationEventRepository events;

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
    events = MedicationEventRepository(
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
    test('round-trips kind, diffs and note through the encrypted payload',
        () async {
      final event = await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.fieldsChanged,
        diffs: const [
          MedicationFieldDiff(field: 'dose', previous: '10mg', current: '20mg'),
        ],
        note: 'Per Dr. Chen',
      );

      final listed = await events.listForMedication('med-1');
      expect(listed, hasLength(1));
      expect(listed.single.id, event.id);
      expect(listed.single.kind, MedicationEventKind.fieldsChanged);
      expect(listed.single.diffs.single.field, 'dose');
      expect(listed.single.diffs.single.previous, '10mg');
      expect(listed.single.diffs.single.current, '20mg');
      expect(listed.single.note, 'Per Dr. Chen');
    });

    test('defaults occurredAt to now when no value is provided', () async {
      final before = tickingClock();
      final event = await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.created,
      );
      expect(event.occurredAt.isAfter(before), isTrue);
    });

    test('honours a caller-supplied occurredAt (for manual backfill)',
        () async {
      final backfilled = DateTime.utc(2020, 3);
      final event = await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
        occurredAt: backfilled,
        note: 'Initial prescription from 2020',
      );
      expect(event.occurredAt, backfilled);
    });

    test(
        'encrypts the payload — the raw DB blob does not contain the note '
        'plaintext', () async {
      await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
        note: 'VerySpecificEventToken',
      );
      final row = await db.select(db.medicationEvents).getSingle();
      final asString = String.fromCharCodes(row.payload);
      expect(asString.contains('VerySpecificEventToken'), isFalse);
    });

    test('each event gets a fresh envelope (distinct nonce) on the wire',
        () async {
      // Two events with byte-identical payloads must still encrypt
      // to distinct ciphertexts — otherwise an attacker with
      // access to the DB could trivially identify duplicate
      // regimen changes.
      await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
        note: 'same',
      );
      await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
        note: 'same',
      );
      final rows = await db.select(db.medicationEvents).get();
      expect(rows, hasLength(2));
      final envA = EncryptedPayload.fromBytes(rows[0].payload);
      final envB = EncryptedPayload.fromBytes(rows[1].payload);
      expect(envA.nonce, isNot(equals(envB.nonce)));
    });
  });

  group('listForMedication', () {
    test('returns newest-first by occurredAt, filtering by medication id',
        () async {
      await events.create(
        medicationId: 'med-A',
        personId: alexId,
        kind: MedicationEventKind.created,
        occurredAt: DateTime.utc(2025),
      );
      await events.create(
        medicationId: 'med-A',
        personId: alexId,
        kind: MedicationEventKind.note,
        occurredAt: DateTime.utc(2026, 6),
        note: 'mid',
      );
      await events.create(
        medicationId: 'med-A',
        personId: alexId,
        kind: MedicationEventKind.fieldsChanged,
        occurredAt: DateTime.utc(2027),
        diffs: const [
          MedicationFieldDiff(field: 'dose', current: '5mg'),
        ],
      );
      // Different med — must not appear in med-A's timeline.
      await events.create(
        medicationId: 'med-B',
        personId: alexId,
        kind: MedicationEventKind.created,
      );

      final listed = await events.listForMedication('med-A');

      expect(listed, hasLength(3));
      expect(
        listed.map((e) => e.occurredAt.year),
        [2027, 2026, 2025],
      );
    });

    test('returns empty for an unknown medication id', () async {
      final listed = await events.listForMedication('never-seen');
      expect(listed, isEmpty);
    });

    test('excludes archived events', () async {
      final event = await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
        note: 'to-archive',
      );
      await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
        note: 'keeper',
      );

      await events.archive(event.id);

      final listed = await events.listForMedication('med-1');
      expect(listed, hasLength(1));
      expect(listed.single.note, 'keeper');
    });
  });

  group('archive', () {
    test('throws MedicationEventNotFoundError for a missing id', () async {
      await expectLater(
        () => events.archive('not-a-real-event'),
        throwsA(isA<MedicationEventNotFoundError>()),
      );
    });

    test('double-archive throws (no silent re-archive)', () async {
      final event = await events.create(
        medicationId: 'med-1',
        personId: alexId,
        kind: MedicationEventKind.note,
      );
      await events.archive(event.id);
      await expectLater(
        () => events.archive(event.id),
        throwsA(isA<MedicationEventNotFoundError>()),
      );
    });
  });
}
