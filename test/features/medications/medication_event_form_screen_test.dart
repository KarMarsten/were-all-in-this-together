import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_event_form_screen.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

/// Widget tests for `MedicationEventFormScreen` — the manual-entry
/// form that lets users backfill past regimen changes as free-text
/// notes on a medication's timeline.
///
/// Focus is on the contract the rest of the app depends on:
/// "pressing Save writes an event of kind `note` against the right
/// medication, with the chosen date and trimmed note". The date-
/// picker interaction itself (tap Change → pick a date) is
/// intentionally not exercised here — that UI is Flutter-owned and
/// exercising it in a widget test gives us more flake than coverage.
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

  Widget wrapForm({
    required String medicationId,
    required String personId,
  }) =>
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cryptoServiceProvider.overrideWithValue(crypto),
          keyStorageProvider.overrideWithValue(keys),
        ],
        child: MaterialApp(
          home: MedicationEventFormScreen(
            medicationId: medicationId,
            personId: personId,
          ),
        ),
      );

  testWidgets('Save writes a note event against the right medication',
      (tester) async {
    await tester.pumpWidget(
      wrapForm(medicationId: 'med-1', personId: alexId),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      '  Started 10mg once daily, per Dr. Chen.  ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final written = await events.listForMedication('med-1');
    expect(written, hasLength(1));
    expect(written.single.kind, MedicationEventKind.note);
    expect(written.single.medicationId, 'med-1');
    expect(written.single.personId, alexId);

    // The save path trims whitespace so a fat-fingered leading
    // space doesn't look weird on the timeline.
    expect(
      written.single.note,
      'Started 10mg once daily, per Dr. Chen.',
    );
  });

  testWidgets('empty note blocks save with a validation message',
      (tester) async {
    await tester.pumpWidget(
      wrapForm(medicationId: 'med-1', personId: alexId),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a short description'), findsOneWidget);
    final written = await events.listForMedication('med-1');
    expect(written, isEmpty);
  });

  testWidgets('whitespace-only note is treated as empty', (tester) async {
    await tester.pumpWidget(
      wrapForm(medicationId: 'med-1', personId: alexId),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '   \n  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a short description'), findsOneWidget);
    final written = await events.listForMedication('med-1');
    expect(written, isEmpty);
  });
}
