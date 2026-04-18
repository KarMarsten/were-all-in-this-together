import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/appointments/presentation/appointments_list_screen.dart';

import '../../helpers/test_app_scope.dart';

/// Widget tests for the Appointments list flow, exercising the
/// full stack (routing, Riverpod graph, real in-memory DB and
/// crypto) via `buildTestApp()`.
///
/// The harness can't mock `DateTime.now`, so the "past vs upcoming
/// split" logic stays covered by the repository tests. Here we
/// verify the UI surfaces: empty state, no-active-Person state,
/// form submission, title validation.
Future<void> _addPerson(WidgetTester tester, String name) async {
  await tester.tap(find.text('People'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add someone').first);
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
}

Future<void> _openAppointments(WidgetTester tester) async {
  // The Appointments tile lives in the home grid; scroll into view
  // before tapping so the hit test lands cleanly on the default
  // 800x600 test viewport.
  await tester.ensureVisible(find.text('Appointments'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Appointments'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'no Person yet → Appointments list shows an Add-someone-first prompt',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _openAppointments(tester);

      expect(find.text('Add someone first'), findsOneWidget);
      expect(find.text('Add appointment'), findsNothing);
    },
  );

  testWidgets(
    'Person present but no appointments → empty state + CTA + appbar subtitle',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openAppointments(tester);

      expect(find.text('No appointments yet'), findsOneWidget);
      expect(find.text('for Alex'), findsOneWidget);
      // Empty-state button + FAB both render the same label.
      expect(find.text('Add appointment'), findsNWidgets(2));
    },
  );

  testWidgets('adding an appointment returns to the list with the new tile',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openAppointments(tester);
    await tester.tap(find.text('Add appointment').first);
    await tester.pumpAndSettle();

    // We don't drive the native date/time pickers — the form
    // defaults to "next top-of-hour in local time", which will
    // always land in the Upcoming section at test runtime.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Dr. Chen — flu shot',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Chen — flu shot'), findsOneWidget);
    expect(find.text('No appointments yet'), findsNothing);
    expect(find.text('UPCOMING'), findsOneWidget);
  });

  testWidgets('Save with an empty title shows a validation error',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openAppointments(tester);
    await tester.tap(find.text('Add appointment').first);
    await tester.pumpAndSettle();

    // Leave title blank.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a title'), findsOneWidget);
  });

  testWidgets('Non-numeric duration is rejected with a validator message',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openAppointments(tester);
    await tester.tap(find.text('Add appointment').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'x',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration in minutes (optional)'),
      'abc',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a whole number of minutes'), findsOneWidget);
  });

  group('formatDayHeader', () {
    // Pure function; unit-test it directly so the label logic is
    // locked in without requiring a full widget pump.
    final anchor = DateTime(2030, 5, 10, 9);
    DateTime fixedClock() => anchor;

    test('"Today" for the same calendar day', () {
      expect(
        formatDayHeader(
          DateTime(2030, 5, 10),
          now: fixedClock,
        ),
        'Today',
      );
    });

    test('"Tomorrow" for one day ahead', () {
      expect(
        formatDayHeader(
          DateTime(2030, 5, 11),
          now: fixedClock,
        ),
        'Tomorrow',
      );
    });

    test('Weekday name for within-a-week lookahead', () {
      // May 10 2030 is a Friday; May 14 (Tue) is four days out.
      expect(
        formatDayHeader(
          DateTime(2030, 5, 14),
          now: fixedClock,
        ),
        'Tuesday',
      );
    });

    test('ISO date for far-future', () {
      expect(
        formatDayHeader(
          DateTime(2030, 8),
          now: fixedClock,
        ),
        '2030-08-01',
      );
    });

    test('ISO date for past days (used by Past section)', () {
      expect(
        formatDayHeader(
          DateTime(2030),
          now: fixedClock,
        ),
        '2030-01-01',
      );
    });
  });

  group('formatTime', () {
    test('zero-pads hour and minute', () {
      expect(formatTime(DateTime(2030, 5, 10, 9, 5)), '09:05');
      expect(formatTime(DateTime(2030, 5, 10, 13)), '13:00');
    });
  });
}
