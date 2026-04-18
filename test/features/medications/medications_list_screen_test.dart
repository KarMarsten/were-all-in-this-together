import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

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

  testWidgets(
    'schedule editor: "Every day" reveals times; weekday picker hidden',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);
      await tester.tap(find.text('Add medication').first);
      await tester.pumpAndSettle();

      // Default is "As needed": no Times / Days sections rendered.
      expect(find.text('Times'), findsNothing);
      expect(find.text('Days'), findsNothing);

      // Switch to "Every day" and scroll the new section into view.
      final everyDay = find.text('Every day');
      await tester.ensureVisible(everyDay);
      await tester.tap(everyDay);
      await tester.pumpAndSettle();

      expect(find.text('Times'), findsOneWidget);
      expect(find.text('Add time'), findsOneWidget);
      // Daily, not weekly: no day picker.
      expect(find.text('Days'), findsNothing);
    },
  );

  testWidgets(
    'schedule editor: "Specific days" shows the weekday picker',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);
      await tester.tap(find.text('Add medication').first);
      await tester.pumpAndSettle();

      final specificDays = find.text('Specific days');
      await tester.ensureVisible(specificDays);
      await tester.tap(specificDays);
      await tester.pumpAndSettle();

      expect(find.text('Days'), findsOneWidget);
      expect(find.text('Times'), findsOneWidget);
    },
  );

  testWidgets(
    'a med saved with a daily schedule shows the schedule hint on its tile',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMedications(tester);

      // Save-path heavy tests of the time picker would be brittle (it
      // hits a modal clock dialog). Instead we navigate through the
      // form with the default kind switch and rely on repository tests
      // to cover persistence of times. Here we just prove the list
      // subtitle renders *something* when the schedule isn't
      // asNeeded — we use the edit flow to verify seeded state shows.
      // So: seed via the form and then re-open to observe.
      await tester.tap(find.text('Add medication').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Morning meds',
      );
      await tester.ensureVisible(find.text('Every day'));
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();
      // No time added — the subtitle falls back to "no times set".
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on the list, the hint text appears in the subtitle.
      expect(find.text('Morning meds'), findsOneWidget);
      expect(find.textContaining('no times set'), findsOneWidget);
    },
  );

  testWidgets(
    'isReminderEligible matches what the editor produces — daily with no '
    'times is not reminder-eligible',
    (tester) async {
      // Pure domain check but lives with the widget tests because the
      // editor's transition rules are the thing we care about in
      // practice. Exercising the domain directly keeps this fast.
      const empty = MedicationSchedule(kind: ScheduleKind.daily);
      expect(empty.isReminderEligible, isFalse);

      const withTime = MedicationSchedule(
        kind: ScheduleKind.daily,
        times: [ScheduledTime(hour: 8, minute: 0)],
      );
      expect(withTime.isReminderEligible, isTrue);
    },
  );
}
