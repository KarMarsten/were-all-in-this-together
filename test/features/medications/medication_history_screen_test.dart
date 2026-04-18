import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_history_screen.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

/// Focused widget test for `MedicationHistoryScreen`.
///
/// Uses a live (in-memory) database + event repo — the screen's
/// rendering logic is tightly coupled to decoded `MedicationEvent`s
/// and mocking the repo would hide bugs in the decode path. We
/// keep the widget tree minimal: just a `MaterialApp` + the
/// screen, with `ProviderScope` overrides pointing at our test
/// stack.
void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late MedicationEventRepository events;
  late String alexId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
    events = MedicationEventRepository(
      database: db,
      crypto: crypto,
      keys: keys,
    );
    final people = PersonRepository(
      database: db,
      crypto: crypto,
      keys: keys,
    );
    final alex = await people.create(displayName: 'Alex');
    alexId = alex.id;
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrapScreen(String medicationId) => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cryptoServiceProvider.overrideWithValue(crypto),
          keyStorageProvider.overrideWithValue(keys),
        ],
        child: MaterialApp(
          home: MedicationHistoryScreen(medicationId: medicationId),
        ),
      );

  testWidgets('empty state renders when no events exist', (tester) async {
    await tester.pumpWidget(wrapScreen('no-events'));
    await tester.pumpAndSettle();

    expect(find.text('No history yet.'), findsOneWidget);
  });

  testWidgets('renders created + fieldsChanged events reverse-chron',
      (tester) async {
    await events.create(
      medicationId: 'med-1',
      personId: alexId,
      kind: MedicationEventKind.created,
      occurredAt: DateTime.utc(2026, 4, 1, 10),
    );
    await events.create(
      medicationId: 'med-1',
      personId: alexId,
      kind: MedicationEventKind.fieldsChanged,
      occurredAt: DateTime.utc(2026, 4, 18, 14),
      diffs: const [
        MedicationFieldDiff(field: 'dose', previous: '10mg', current: '20mg'),
      ],
    );

    await tester.pumpWidget(wrapScreen('med-1'));
    await tester.pumpAndSettle();

    // Both events present.
    expect(find.text('Updated 1 field'), findsOneWidget);
    expect(find.text('Added to this person'), findsOneWidget);

    // The dose diff renders with field label + prev → curr.
    expect(find.text('Dose: 10mg → 20mg'), findsOneWidget);

    // Reverse-chron: "Updated" (2026-04-18) comes before "Added"
    // (2026-04-01) in the rendered list.
    final updatedPos = tester.getTopLeft(find.text('Updated 1 field')).dy;
    final addedPos = tester.getTopLeft(find.text('Added to this person')).dy;
    expect(updatedPos, lessThan(addedPos));
  });

  testWidgets('cleared field renders as "cleared (was …)"',
      (tester) async {
    await events.create(
      medicationId: 'med-1',
      personId: alexId,
      kind: MedicationEventKind.fieldsChanged,
      occurredAt: DateTime.utc(2026, 4),
      diffs: const [
        MedicationFieldDiff(field: 'endDate', previous: '2026-03-15'),
      ],
    );

    await tester.pumpWidget(wrapScreen('med-1'));
    await tester.pumpAndSettle();

    expect(find.text('End date cleared (was 2026-03-15)'), findsOneWidget);
  });

  testWidgets('archived + restored kinds render with their own titles',
      (tester) async {
    await events.create(
      medicationId: 'med-1',
      personId: alexId,
      kind: MedicationEventKind.archived,
      occurredAt: DateTime.utc(2026, 4),
    );
    await events.create(
      medicationId: 'med-1',
      personId: alexId,
      kind: MedicationEventKind.restored,
      occurredAt: DateTime.utc(2026, 4, 2),
    );

    await tester.pumpWidget(wrapScreen('med-1'));
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Restored'), findsOneWidget);
  });
}
