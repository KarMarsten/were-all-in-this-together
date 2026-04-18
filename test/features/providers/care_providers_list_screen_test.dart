import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app_scope.dart';

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

Future<void> _openProviders(WidgetTester tester) async {
  // The Providers tile lives in the second row of the home-screen grid,
  // which the default 800x600 test viewport pushes under the Calm bar.
  // Scroll it into view before tapping so the hit test lands cleanly.
  await tester.ensureVisible(find.text('Providers'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Providers'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'no Person yet → Providers list shows an Add-someone-first prompt',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _openProviders(tester);

      expect(find.text('Add someone first'), findsOneWidget);
      // No Add-provider FAB should be reachable in this state.
      expect(find.text('Add provider'), findsNothing);
    },
  );

  testWidgets(
    'Person present but no providers → empty state + CTA + appbar subtitle',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openProviders(tester);

      expect(find.text('No providers yet'), findsOneWidget);
      expect(find.text('for Alex'), findsOneWidget);
      // Empty-state button + FAB both render the same label.
      expect(find.text('Add provider'), findsNWidgets(2));
    },
  );

  testWidgets('adding a provider returns to the list with the new tile',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openProviders(tester);
    await tester.tap(find.text('Add provider').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Dr. Chen',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Specialty (optional)'),
      'DBP',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // New tile appears, grouped under its kind header (default
    // `specialist` → 'Specialists').
    expect(find.text('Dr. Chen'), findsOneWidget);
    expect(find.text('Specialists'), findsOneWidget);
    expect(find.text('No providers yet'), findsNothing);
  });

  testWidgets('Save with an empty name shows a validation error',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openProviders(tester);
    await tester.tap(find.text('Add provider').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a name'), findsOneWidget);
  });

  testWidgets('portal URL without a scheme is rejected at validation',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openProviders(tester);
    await tester.tap(find.text('Add provider').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Dr. Chen',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Portal URL (optional)'),
      'mychart.example.com',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Must start with http:// or https://'), findsOneWidget);
  });
}
