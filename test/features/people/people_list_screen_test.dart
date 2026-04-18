import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app_scope.dart';

void main() {
  testWidgets('empty roster shows the empty state and the add button',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Navigate to People from the home bottom bar.
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();

    expect(find.text('No one here yet'), findsOneWidget);
    // Add button appears both in the empty state and in the FAB.
    expect(find.text('Add someone'), findsNWidgets(2));
  });

  testWidgets('adding a person navigates back and shows them in the list',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();

    // Open the new-person form from the empty state CTA (the first
    // "Add someone" in the widget tree — the FAB is also present but either
    // entry point is valid for this test).
    await tester.tap(find.text('Add someone').first);
    await tester.pumpAndSettle();

    expect(find.text('Add someone'), findsOneWidget); // the AppBar title

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('No one here yet'), findsNothing);
  });

  testWidgets('Save with an empty name shows a validation error',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_add_alt_1).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a name'), findsOneWidget);
  });

  testWidgets('tapping a Person opens the edit screen prefilled',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add someone').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Alex'), findsOneWidget);
    // The name field should be prefilled.
    final nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Name'),
    );
    expect(nameField.controller?.text, 'Alex');
  });

  testWidgets('Remove → confirm soft-deletes and returns to an empty list',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add someone').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove Alex'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Alex?'), findsOneWidget);
    expect(
      find.textContaining("can't fully erase yet"),
      findsOneWidget,
    );

    // Confirm in the dialog. There are two 'Remove' texts on screen now (the
    // form's outlined button + the dialog's destructive button); the last
    // is the dialog action.
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(find.text('No one here yet'), findsOneWidget);
    expect(find.text('Alex'), findsNothing);
  });

  testWidgets('Remove → Cancel leaves the Person in place', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add someone').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Alex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Still on the edit screen.
    expect(find.text('Edit Alex'), findsOneWidget);

    // Going back to the list, Alex is still there.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
  });
}
