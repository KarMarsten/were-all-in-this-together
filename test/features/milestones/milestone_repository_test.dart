import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

/// Integration-ish tests for `MilestoneRepository` against a real
/// in-memory Drift DB and real crypto. Pinned clock keeps timestamp
/// assertions deterministic without sleep().
void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late MilestoneRepository milestones;
  late String alexId;

  // Ticking UTC clock — one ms per call. Used for createdAt /
  // updatedAt / deletedAt.
  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2030).add(Duration(milliseconds: clockCallCount));
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
    milestones = MilestoneRepository(
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
    test('returns a Milestone with every provided field', () async {
      final m = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.diagnosis,
        title: 'Diagnosed with ASD',
        occurredAt: DateTime.utc(2022, 5, 3),
        precision: MilestonePrecision.day,
        providerId: 'prov-1',
        notes: 'Dr. Chen was very kind',
      );

      expect(m.id, isNotEmpty);
      expect(m.personId, alexId);
      expect(m.kind, MilestoneKind.diagnosis);
      expect(m.title, 'Diagnosed with ASD');
      expect(m.occurredAt, DateTime.utc(2022, 5, 3));
      expect(m.precision, MilestonePrecision.day);
      expect(m.providerId, 'prov-1');
      expect(m.notes, 'Dr. Chen was very kind');
      expect(m.deletedAt, isNull);
      expect(m.rowVersion, 1);
    });

    test('rejects a blank title', () async {
      expect(
        () => milestones.create(
          personId: alexId,
          kind: MilestoneKind.other,
          title: '   ',
          occurredAt: DateTime.utc(2022),
          precision: MilestonePrecision.year,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when the owning Person has no key on this device',
        () async {
      expect(
        () => milestones.create(
          personId: 'no-such-person',
          kind: MilestoneKind.other,
          title: 'orphan',
          occurredAt: DateTime.utc(2022),
          precision: MilestonePrecision.year,
        ),
        throwsA(isA<MilestoneKeyMissingError>()),
      );
    });

    test('canonicalises occurredAt to start-of-period per precision',
        () async {
      final yearly = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.life,
        title: 'Moved house',
        occurredAt: DateTime.utc(2019, 7, 18, 14, 30),
        precision: MilestonePrecision.year,
      );
      final monthly = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.vaccine,
        title: 'Flu shot',
        occurredAt: DateTime.utc(2024, 3, 14, 9),
        precision: MilestonePrecision.month,
      );
      final daily = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.health,
        title: 'ER visit',
        occurredAt: DateTime.utc(2024, 3, 14, 9, 37),
        precision: MilestonePrecision.day,
      );
      final exact = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.development,
        title: 'First steps',
        occurredAt: DateTime.utc(2024, 3, 14, 9, 37, 12),
        precision: MilestonePrecision.exact,
      );

      expect(yearly.occurredAt, DateTime.utc(2019));
      expect(monthly.occurredAt, DateTime.utc(2024, 3));
      expect(daily.occurredAt, DateTime.utc(2024, 3, 14));
      expect(exact.occurredAt, DateTime.utc(2024, 3, 14, 9, 37, 12));
    });

    test('round-trips through findById including decryption', () async {
      final created = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.diagnosis,
        title: 'Round-trip',
        occurredAt: DateTime.utc(2022, 5, 3),
        precision: MilestonePrecision.day,
        notes: 'secret notes',
      );

      final reloaded = await milestones.findById(created.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.title, 'Round-trip');
      expect(reloaded.notes, 'secret notes');
      expect(reloaded.kind, MilestoneKind.diagnosis);
      expect(reloaded.precision, MilestonePrecision.day);
      expect(reloaded.occurredAt, DateTime.utc(2022, 5, 3));
    });
  });

  group('listActiveForPerson', () {
    test('sorts by occurredAt descending and excludes archived', () async {
      final oldest = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.life,
        title: 'Born',
        occurredAt: DateTime.utc(2018),
        precision: MilestonePrecision.year,
      );
      final middle = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.vaccine,
        title: 'MMR',
        occurredAt: DateTime.utc(2020, 1, 15),
        precision: MilestonePrecision.day,
      );
      final newest = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.diagnosis,
        title: 'ASD',
        occurredAt: DateTime.utc(2024, 3),
        precision: MilestonePrecision.month,
      );
      final archived = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.other,
        title: 'Gone',
        occurredAt: DateTime.utc(2023),
        precision: MilestonePrecision.year,
      );
      await milestones.archive(archived.id);

      final list = await milestones.listActiveForPerson(alexId);
      expect(
        list.map((m) => m.id).toList(),
        [newest.id, middle.id, oldest.id],
      );
    });

    test('scopes by personId', () async {
      final sibling = await people.create(displayName: 'Sibling');
      await milestones.create(
        personId: sibling.id,
        kind: MilestoneKind.life,
        title: "Sibling's milestone",
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );
      final mine = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.life,
        title: 'Mine',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );

      final list = await milestones.listActiveForPerson(alexId);
      expect(list.map((m) => m.id), [mine.id]);
    });
  });

  group('update', () {
    test('bumps rowVersion, re-canonicalises date, re-encrypts payload',
        () async {
      final created = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.diagnosis,
        title: 'First take',
        occurredAt: DateTime.utc(2022, 5, 3),
        precision: MilestonePrecision.day,
      );

      final edited = await milestones.update(
        created.copyWith(
          title: 'Corrected title',
          precision: MilestonePrecision.month,
          occurredAt: DateTime.utc(2022, 5, 3, 17, 22),
          notes: 'Added notes',
        ),
      );

      expect(edited.rowVersion, created.rowVersion + 1);
      expect(edited.title, 'Corrected title');
      expect(edited.notes, 'Added notes');
      expect(edited.precision, MilestonePrecision.month);
      expect(edited.occurredAt, DateTime.utc(2022, 5));

      final reloaded = await milestones.findById(created.id);
      expect(reloaded!.title, 'Corrected title');
      expect(reloaded.notes, 'Added notes');
      expect(reloaded.occurredAt, DateTime.utc(2022, 5));
    });

    test('refuses a personId transfer', () async {
      final sibling = await people.create(displayName: 'Sibling');
      final mine = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.life,
        title: 'x',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );

      expect(
        () => milestones.update(mine.copyWith(personId: sibling.id)),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a blank title on update', () async {
      final m = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.life,
        title: 'Keep me',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );
      expect(
        () => milestones.update(m.copyWith(title: '  ')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when the id is unknown', () async {
      final phantom = Milestone(
        id: 'no-such-id',
        personId: alexId,
        kind: MilestoneKind.other,
        title: 'phantom',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2020),
      );
      expect(
        () => milestones.update(phantom),
        throwsA(isA<MilestoneNotFoundError>()),
      );
    });
  });

  group('archive / restore', () {
    test('archive then restore flips deletedAt and is observable via the lists',
        () async {
      final m = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.vaccine,
        title: 'Flu shot',
        occurredAt: DateTime.utc(2024, 10),
        precision: MilestonePrecision.month,
      );

      await milestones.archive(m.id);
      expect(
        (await milestones.listActiveForPerson(alexId)).map((m) => m.id),
        isNot(contains(m.id)),
      );
      expect(
        (await milestones.listArchivedForPerson(alexId)).map((m) => m.id),
        contains(m.id),
      );

      await milestones.restore(m.id);
      expect(
        (await milestones.listActiveForPerson(alexId)).map((m) => m.id),
        contains(m.id),
      );
      expect(
        (await milestones.listArchivedForPerson(alexId)).map((m) => m.id),
        isNot(contains(m.id)),
      );
    });

    test('archiving an already-archived row throws', () async {
      final m = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.other,
        title: 'x',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );
      await milestones.archive(m.id);
      expect(
        () => milestones.archive(m.id),
        throwsA(isA<MilestoneNotFoundError>()),
      );
    });

    test('restoring a non-archived row throws', () async {
      final m = await milestones.create(
        personId: alexId,
        kind: MilestoneKind.other,
        title: 'x',
        occurredAt: DateTime.utc(2020),
        precision: MilestonePrecision.year,
      );
      expect(
        () => milestones.restore(m.id),
        throwsA(isA<MilestoneNotFoundError>()),
      );
    });
  });

  group('formatMilestoneDate', () {
    test('year precision renders as just the year', () {
      final m = _fake(
        precision: MilestonePrecision.year,
        occurredAt: DateTime.utc(2019),
      );
      expect(formatMilestoneDate(m), '2019');
    });

    test('month precision renders as "Month Year"', () {
      final m = _fake(
        precision: MilestonePrecision.month,
        occurredAt: DateTime.utc(2024, 3),
      );
      expect(formatMilestoneDate(m), 'March 2024');
    });

    test('day precision renders as "Mon D, Year"', () {
      final m = _fake(
        precision: MilestonePrecision.day,
        occurredAt: DateTime.utc(2024, 3, 14),
      );
      expect(formatMilestoneDate(m), 'Mar 14, 2024');
    });
  });
}

Milestone _fake({
  required MilestonePrecision precision,
  required DateTime occurredAt,
}) =>
    Milestone(
      id: 'id',
      personId: 'p',
      kind: MilestoneKind.other,
      title: 't',
      occurredAt: occurredAt,
      precision: precision,
      createdAt: DateTime.utc(2020),
      updatedAt: DateTime.utc(2020),
    );
