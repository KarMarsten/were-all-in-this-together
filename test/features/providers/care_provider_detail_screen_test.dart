import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

import '../../helpers/recording_url_opener.dart';
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
  await tester.ensureVisible(find.text('Providers'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Providers'));
  await tester.pumpAndSettle();
}

/// Seeds a Person + a fully-populated care provider, then lands on the
/// detail screen. Returns the recording opener so each test can assert
/// which tap action fired.
Future<RecordingUrlOpener> _seedAndOpenDetail(WidgetTester tester) async {
  final opener = RecordingUrlOpener();
  await tester.pumpWidget(
    buildTestApp(
      extraOverrides: <Override>[
        urlOpenerProvider.overrideWith((_) => opener),
      ],
    ),
  );
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
    find.widgetWithText(TextFormField, 'Phone (optional)'),
    '+1 555-111-2222',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email (optional)'),
    'office@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Address (optional)'),
    '1 Elm St',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Portal URL (optional)'),
    'https://mychart.example.com',
  );
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // List tile tap → detail screen.
  await tester.tap(find.text('Dr. Chen'));
  await tester.pumpAndSettle();

  return opener;
}

void main() {
  testWidgets('tap-to-call routes through UrlOpener with the phone number',
      (tester) async {
    final opener = await _seedAndOpenDetail(tester);

    await tester.tap(find.text('+1 555-111-2222'));
    await tester.pumpAndSettle();

    expect(opener.telCalls, ['+1 555-111-2222']);
    expect(opener.webCalls, isEmpty);
    expect(opener.mapCalls, isEmpty);
  });

  testWidgets('tap-to-portal opens the web URL', (tester) async {
    final opener = await _seedAndOpenDetail(tester);

    await tester.ensureVisible(find.text('https://mychart.example.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('https://mychart.example.com'));
    await tester.pumpAndSettle();

    expect(opener.webCalls, ['https://mychart.example.com']);
  });

  testWidgets('tap-to-email opens Mail', (tester) async {
    final opener = await _seedAndOpenDetail(tester);

    await tester.tap(find.text('office@example.com'));
    await tester.pumpAndSettle();

    expect(opener.emailCalls, ['office@example.com']);
  });

  testWidgets('tap-to-map opens the address', (tester) async {
    final opener = await _seedAndOpenDetail(tester);

    await tester.ensureVisible(find.text('1 Elm St'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Elm St'));
    await tester.pumpAndSettle();

    expect(opener.mapCalls, ['1 Elm St']);
  });

  testWidgets('failed open surfaces a SnackBar', (tester) async {
    // Exercise the failure branch: the opener reports `false`, and the
    // detail screen surfaces a friendly SnackBar.
    final opener = await _seedAndOpenDetail(tester);
    opener.succeed = false;

    await tester.tap(find.text('+1 555-111-2222'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't start the call."), findsOneWidget);
  });
}
