import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/reports/data/adherence_report_service.dart';
import 'package:were_all_in_this_together/features/reports/domain/adherence_report_row.dart';

import '../../helpers/in_memory_key_storage.dart';

void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late MedicationRepository meds;
  late DoseLogRepository logs;
  late AdherenceReportService service;

  var clockTicks = 0;
  DateTime tickingClock() {
    clockTicks++;
    return DateTime.utc(2026).add(Duration(milliseconds: clockTicks));
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
    clockTicks = 0;
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
    logs = DoseLogRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    service = AdherenceReportService(
      people: people,
      medications: meds,
      doseLogs: logs,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('returns empty when there are no People', () async {
    final rows = await service.fetch(
      AdherenceReportQuery(
        fromInclusive: DateTime.utc(2026),
        toExclusive: DateTime.utc(2026, 2),
      ),
    );
    expect(rows, isEmpty);
  });

  test('joins logs with medication + person names, sorted desc', () async {
    final alex = await people.create(displayName: 'Alex');
    final jamie = await people.create(displayName: 'Jamie');
    final alexMed = await meds.create(
      personId: alex.id,
      name: 'Methylphenidate',
      dose: '10mg',
    );
    final jamieMed = await meds.create(
      personId: jamie.id,
      name: 'Sertraline',
      dose: '50mg',
    );

    final earlier = DateTime.utc(2026, 4, 18, 8);
    final later = DateTime.utc(2026, 4, 18, 20);

    await logs.record(
      personId: alex.id,
      medicationId: alexMed.id,
      scheduledAt: earlier,
      outcome: DoseOutcome.taken,
    );
    await logs.record(
      personId: jamie.id,
      medicationId: jamieMed.id,
      scheduledAt: later,
      outcome: DoseOutcome.skipped,
    );

    final rows = await service.fetch(
      AdherenceReportQuery(
        fromInclusive: DateTime.utc(2026, 4),
        toExclusive: DateTime.utc(2026, 5),
      ),
    );

    expect(rows, hasLength(2));
    // Newest scheduled first.
    expect(rows.first.scheduledAt, later);
    expect(rows.first.medicationName, 'Sertraline');
    expect(rows.first.personName, 'Jamie');
    expect(rows.first.outcome, DoseOutcome.skipped);

    expect(rows.last.scheduledAt, earlier);
    expect(rows.last.medicationName, 'Methylphenidate');
    expect(rows.last.personName, 'Alex');
    expect(rows.last.outcome, DoseOutcome.taken);

    // Phase-1 placeholder until multi-caregiver lands.
    for (final r in rows) {
      expect(r.ackedBy, kThisDeviceAckLabel);
    }
  });

  test('filters by personId when provided', () async {
    final alex = await people.create(displayName: 'Alex');
    final jamie = await people.create(displayName: 'Jamie');
    final alexMed = await meds.create(
      personId: alex.id,
      name: 'Methylphenidate',
    );
    final jamieMed = await meds.create(
      personId: jamie.id,
      name: 'Sertraline',
    );

    await logs.record(
      personId: alex.id,
      medicationId: alexMed.id,
      scheduledAt: DateTime.utc(2026, 4, 18, 8),
      outcome: DoseOutcome.taken,
    );
    await logs.record(
      personId: jamie.id,
      medicationId: jamieMed.id,
      scheduledAt: DateTime.utc(2026, 4, 18, 20),
      outcome: DoseOutcome.taken,
    );

    final rows = await service.fetch(
      AdherenceReportQuery(
        fromInclusive: DateTime.utc(2026, 4),
        toExclusive: DateTime.utc(2026, 5),
        personId: alex.id,
      ),
    );

    expect(rows, hasLength(1));
    expect(rows.single.personId, alex.id);
    expect(rows.single.medicationName, 'Methylphenidate');
  });

  test('half-open date window excludes rows on the upper bound', () async {
    final alex = await people.create(displayName: 'Alex');
    final med = await meds.create(
      personId: alex.id,
      name: 'Methylphenidate',
    );

    final inside = DateTime.utc(2026, 4, 17, 23, 59);
    final boundary = DateTime.utc(2026, 4, 18); // exclusive upper bound

    await logs.record(
      personId: alex.id,
      medicationId: med.id,
      scheduledAt: inside,
      outcome: DoseOutcome.taken,
    );
    await logs.record(
      personId: alex.id,
      medicationId: med.id,
      scheduledAt: boundary,
      outcome: DoseOutcome.taken,
    );

    final rows = await service.fetch(
      AdherenceReportQuery(
        fromInclusive: DateTime.utc(2026, 4, 17),
        toExclusive: DateTime.utc(2026, 4, 18),
      ),
    );

    expect(rows, hasLength(1));
    expect(rows.single.scheduledAt, inside);
  });

  test('resolves archived medications — name survives archival', () async {
    final alex = await people.create(displayName: 'Alex');
    final med = await meds.create(
      personId: alex.id,
      name: 'Methylphenidate',
    );
    await logs.record(
      personId: alex.id,
      medicationId: med.id,
      scheduledAt: DateTime.utc(2026, 4, 18, 8),
      outcome: DoseOutcome.taken,
    );
    await meds.archive(med.id);

    final rows = await service.fetch(
      AdherenceReportQuery(
        fromInclusive: DateTime.utc(2026, 4),
        toExclusive: DateTime.utc(2026, 5),
      ),
    );

    expect(rows, hasLength(1));
    expect(rows.single.medicationName, 'Methylphenidate');
  });

  test('undone (soft-deleted) logs are excluded', () async {
    final alex = await people.create(displayName: 'Alex');
    final med = await meds.create(
      personId: alex.id,
      name: 'Methylphenidate',
    );
    final scheduledAt = DateTime.utc(2026, 4, 18, 8);
    await logs.record(
      personId: alex.id,
      medicationId: med.id,
      scheduledAt: scheduledAt,
      outcome: DoseOutcome.taken,
    );
    await logs.undo(medicationId: med.id, scheduledAt: scheduledAt);

    final rows = await service.fetch(
      AdherenceReportQuery(
        fromInclusive: DateTime.utc(2026, 4),
        toExclusive: DateTime.utc(2026, 5),
      ),
    );

    expect(rows, isEmpty);
  });
}
