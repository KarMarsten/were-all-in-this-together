import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';

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

Future<void> _openProfile(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

/// Scrolls profile content and opens the add-entry form (filled or outlined
/// Add entry control).
Future<void> _scrollProfileAndOpenAddEntry(WidgetTester tester) async {
  final listFinder = find.byType(ListView);
  expect(listFinder, findsOneWidget);
  await tester.drag(listFinder, const Offset(0, -800));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add entry').first);
  await tester.pumpAndSettle();
}

/// Matches [SnackBar.duration] on structured entry save (2s).
Future<void> _pumpPastEntrySavedSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2100));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no Person yet → Profile explains roster is required',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _openProfile(tester);

    expect(
      find.textContaining('Add someone to the roster first'),
      findsOneWidget,
    );
  });

  testWidgets(
    'with Person → shows baselines form and can save',
    (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Sam');
    await _openProfile(tester);

    expect(find.textContaining('Profile · Sam'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'AAC board in backpack',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets(
    'Add entry → save without recommended details shows confirm dialog',
    (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Pat');
    await _openProfile(tester);

    await _scrollProfileAndOpenAddEntry(tester);

    await tester.tap(find.byType(DropdownButtonFormField<ProfileEntrySection>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Early sign').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Tapping knees');

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save without details?'), findsOneWidget);

    await tester.tap(find.text('Back to edit'));
    await tester.pumpAndSettle();

    expect(find.text('Save without details?'), findsNothing);
  });

  testWidgets(
    'Add entry → save without recommended details → Save anyway persists',
    (tester) async {
      const savedLabel = 'Save-anyway profile line';

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

    await _addPerson(tester, 'Chris');
    await _openProfile(tester);

    await _scrollProfileAndOpenAddEntry(tester);

    await tester.tap(
      find.byType(DropdownButtonFormField<ProfileEntrySection>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Early sign').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        savedLabel,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Save'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save without details?'), findsOneWidget);
      await tester.tap(find.text('Save anyway'));
      await tester.pumpAndSettle();

      expect(find.text('Save without details?'), findsNothing);
      expect(find.text('Add profile entry'), findsNothing);

      await tester.ensureVisible(find.text(savedLabel));
      await tester.pumpAndSettle();

      expect(find.text(savedLabel), findsOneWidget);
    },
  );

  testWidgets(
    'Structured entry details show on profile list after save',
    (tester) async {
      const label = 'Hand flapping';
      const details = 'Often when excited at the playground.';

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

    await _addPerson(tester, 'Dana');
    await _openProfile(tester);

    await _scrollProfileAndOpenAddEntry(tester);

    final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), label);
      await tester.enterText(fields.at(1), details);

      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Save'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Add profile entry'), findsNothing);

      await tester.ensureVisible(find.text(details));
      await tester.pumpAndSettle();

      expect(find.text(details), findsOneWidget);
    },
  );

  testWidgets(
    'Structured entries load error shows Try again; retry recovers',
    (tester) async {
      var loadsAfterPerson = 0;

      await tester.pumpWidget(
        buildTestApp(
          extraOverrides: [
            profileEntriesForActivePersonProvider.overrideWith((ref) async {
              final personId = await ref.watch(activePersonIdProvider.future);
              if (personId == null) return const <ProfileEntry>[];
              loadsAfterPerson++;
              if (loadsAfterPerson == 1) {
                throw StateError('temporary load failure');
              }
              return const <ProfileEntry>[];
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _addPerson(tester, 'Ryu');
      await _openProfile(tester);

      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load entries'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load entries'), findsNothing);
      expect(find.text('No entries yet.'), findsOneWidget);
    },
  );

  testWidgets('Structured entry edit saves new label', (tester) async {
    const oldLabel = 'First label';
    const newLabel = 'Renamed label';

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Noah');
    await _openProfile(tester);
    await _scrollProfileAndOpenAddEntry(tester);

    await tester.enterText(find.byType(TextFormField).first, oldLabel);
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    await _pumpPastEntrySavedSnackBar(tester);

    await tester.ensureVisible(find.text(oldLabel));
    await tester.tap(
      find.ancestor(
        of: find.text(oldLabel),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit entry'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, newLabel);
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(newLabel));
    await tester.pumpAndSettle();

    expect(find.text(newLabel), findsOneWidget);
    expect(find.text(oldLabel), findsNothing);
  });

  testWidgets('Structured entry archive removes from list', (tester) async {
    const label = 'Line to archive';

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await _addPerson(tester, 'Opal');
    await _openProfile(tester);
    await _scrollProfileAndOpenAddEntry(tester);

    await tester.enterText(find.byType(TextFormField).first, label);
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    await _pumpPastEntrySavedSnackBar(tester);

    await tester.ensureVisible(find.text(label));
    await tester.tap(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit entry'), findsOneWidget);
    await tester.ensureVisible(find.text('Archive entry'));
    await tester.tap(find.text('Archive entry'));
    await tester.pumpAndSettle();

    expect(find.text('Archive this entry?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Archive'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Edit entry'), findsNothing);
    expect(find.text(label), findsNothing);
  });
}
