import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app_scope.dart';

/// Widget tests for the Milestones list flow, exercising the full
/// stack (routing, Riverpod graph, real in-memory DB and crypto)
/// via `buildTestApp()`.
///
/// Milestone dates are user-picked and the widget harness can't
/// drive the native date picker, so precision-specific rendering
/// stays covered by the repo tests + the `formatMilestoneDate`
/// unit tests. Here we verify the UI surfaces around creation,
/// validation, list grouping, and archive/restore.

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

Future<void> _openMilestones(WidgetTester tester) async {
  // The Milestones tile lives in the home grid; scroll into view
  // before tapping so the hit test lands cleanly on the default
  // 800x600 test viewport.
  await tester.ensureVisible(find.text('Milestones & dates'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Milestones & dates'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'no Person yet → Milestones list shows an Add-someone-first prompt',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _openMilestones(tester);

      expect(find.text('Add someone first'), findsOneWidget);
      expect(find.text('Add milestone'), findsNothing);
    },
  );

  testWidgets(
    'Person present but no milestones → empty state + CTA + appbar subtitle',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMilestones(tester);

      expect(find.text('No milestones yet'), findsOneWidget);
      expect(find.text('for Alex'), findsOneWidget);
      // Empty-state button + FAB both render the same label.
      expect(find.text('Add milestone'), findsNWidgets(2));
    },
  );

  testWidgets(
    'adding a milestone returns to the list with the new tile rendered',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMilestones(tester);
      await tester.tap(find.text('Add milestone').first);
      await tester.pumpAndSettle();

      // Default category is "Life event", default precision is
      // "The day" — both are set in initState before the pickers
      // render, so we don't need to touch them here.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Moved to Amsterdam',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Moved to Amsterdam'), findsOneWidget);
      expect(find.text('No milestones yet'), findsNothing);
      // Current year appears as the group header for a "today"-
      // default milestone; we don't assert the exact year so the
      // test stays stable over calendar time.
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    },
  );

  testWidgets('Save with an empty title shows a validation error',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Alex');
    await _openMilestones(tester);
    await tester.tap(find.text('Add milestone').first);
    await tester.pumpAndSettle();

    // Leave title blank.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a title'), findsOneWidget);
  });

  testWidgets(
    'archive → restore round-trips a milestone through the archived section',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Alex');
      await _openMilestones(tester);
      await tester.tap(find.text('Add milestone').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Flu shot',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Open the edit form and archive.
      await tester.tap(find.text('Flu shot'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Archive Flu shot'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Archive Flu shot'));
      await tester.pumpAndSettle();
      // Confirm in the dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
      await tester.pumpAndSettle();

      // Active list no longer shows it; the archived section does.
      expect(find.text('No milestones yet'), findsNothing);
      expect(find.text('Archived (1)'), findsOneWidget);
      // Expand the archived section to reveal the tile.
      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Flu shot'), findsOneWidget);

      // Restore it.
      await tester.tap(find.text('Flu shot'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Restore Flu shot'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Restore Flu shot'));
      await tester.pumpAndSettle();

      // Back on the list, the archived section is gone and the
      // milestone is back in the main list.
      expect(find.text('Archived (1)'), findsNothing);
      expect(find.text('Flu shot'), findsOneWidget);
    },
  );
}
