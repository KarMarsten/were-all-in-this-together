import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app_scope.dart';

void main() {
  testWidgets('empty roster → banner CTA routes to the new-person form',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Add the first person'), findsOneWidget);

    // The banner has an "Add" button; tapping it lands on the form.
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add someone'), findsOneWidget); // AppBar title
  });

  testWidgets('populated roster → banner shows the active Person',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Add someone from the banner.
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Focused on'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
  });

  testWidgets(
    'switcher sheet switches active Person and updates the banner',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Add Alex.
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Alex',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Add Sam via the People screen.
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_add_alt_1).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Sam',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back to home.
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Alex should still be active (oldest, auto-selected first).
      expect(find.text('Alex'), findsOneWidget);

      // Open the switcher by tapping the unfold icon in the banner.
      await tester.tap(find.byIcon(Icons.unfold_more));
      await tester.pumpAndSettle();

      expect(find.text('Switch person'), findsOneWidget);

      // Pick Sam.
      await tester.tap(find.text('Sam'));
      await tester.pumpAndSettle();

      expect(find.text('Focused on'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      // Alex is no longer the banner headline.
      expect(find.text('Alex'), findsNothing);
    },
  );
}
