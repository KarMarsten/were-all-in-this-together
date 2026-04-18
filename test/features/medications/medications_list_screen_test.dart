import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app_scope.dart';

/// Helper: seed a Person named [name] by driving the People flow,
/// returning to home afterwards so each test starts from a known state.
Future<void> _addPerson(WidgetTester tester, String name) async {
  await tester.tap(find.text('People'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add someone').first);
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  // Back out of the People list to Home so tests can drive Medications next.
  await tester.pageBack();
  await tester.pumpAndSettle();
}

Future<void> _openMedications(WidgetTester tester) async {
  await tester.tap(find.text('Medications'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'no Person yet → Medications list shows an Add-someone-first prompt',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _openMedications(tester);

      expect(find.text('Add someone first'), findsOneWidget);
      // The add-medication FAB should not be reachable.
      expect(find.text('Add medication'), findsNothing);
    },
  );

  testWidgets(
    'Person present but no meds → empty state + CTA + appbar subtitle',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);

      expect(find.text('No medications yet'), findsOneWidget);
      expect(find.text('for Alex'), findsOneWidget);
      // Empty-state button + FAB.
      expect(find.text('Add medication'), findsNWidgets(2));
    },
  );

  testWidgets('adding a medication returns to the list with the new tile',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openMedications(tester);
    // Open the form via the empty-state CTA.
    await tester.tap(find.text('Add medication').first);
    await tester.pumpAndSettle();

    expect(find.text('Add medication'), findsOneWidget); // AppBar title

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Methylphenidate',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dose (optional)'),
      '10mg',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Methylphenidate'), findsOneWidget);
    expect(find.text('10mg'), findsOneWidget);
    expect(find.text('No medications yet'), findsNothing);
  });

  testWidgets('Save with an empty name shows a validation error',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openMedications(tester);
    await tester.tap(find.text('Add medication').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a name'), findsOneWidget);
  });

  testWidgets('tapping a med opens the edit screen prefilled', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openMedications(tester);
    await tester.tap(find.text('Add medication').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Alpha',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Alpha'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Name'),
    );
    expect(nameField.controller?.text, 'Alpha');
  });

  testWidgets(
    'Archive → confirm moves the med to the archived section',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);
      await tester.tap(find.text('Add medication').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Alpha',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // Archive button is below the fold on the 800x600 test viewport.
      final archiveButton = find.text('Archive medication');
      await tester.ensureVisible(archiveButton);
      await tester.pumpAndSettle();
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      expect(find.text('Archive Alpha?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
      await tester.pumpAndSettle();

      // Back on the list; Alpha should appear only inside the archived
      // expansion tile, which is collapsed by default.
      expect(find.text('No medications yet'), findsNothing);
      expect(find.text('Archived (1)'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      // Expanding shows the archived med.
      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
    },
  );

  testWidgets(
    'Archive → Cancel leaves the med on the active list',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);
      await tester.tap(find.text('Add medication').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Alpha',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      final archiveButton = find.text('Archive medication');
      await tester.ensureVisible(archiveButton);
      await tester.pumpAndSettle();
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Still on the edit screen for Alpha.
      expect(find.text('Edit Alpha'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Archived (1)'), findsNothing);
    },
  );

  testWidgets(
    'Restore from an archived med brings it back to the active list',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);
      await tester.tap(find.text('Add medication').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Alpha',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Archive it.
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      final archiveButton = find.text('Archive medication');
      await tester.ensureVisible(archiveButton);
      await tester.pumpAndSettle();
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
      await tester.pumpAndSettle();

      // Expand the archived section and tap into the archived med.
      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Alpha'), findsOneWidget);
      final restoreButton = find.text('Restore medication');
      expect(restoreButton, findsOneWidget);

      await tester.ensureVisible(restoreButton);
      await tester.pumpAndSettle();
      await tester.tap(restoreButton);
      await tester.pumpAndSettle();

      // Back on the list, Alpha is active again.
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Archived (1)'), findsNothing);
    },
  );
}
