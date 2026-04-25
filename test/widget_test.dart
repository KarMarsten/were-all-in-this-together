import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('First launch asks for Calm resources setup', (tester) async {
    await tester.pumpWidget(_appWithCalmSetupComplete(false));
    await tester.pumpAndSettle();

    expect(find.text('Set up Calm'), findsOneWidget);
    expect(find.text('Choose supports before you need them'), findsOneWidget);
  });

  testWidgets('App boots to home and shows Calm button', (tester) async {
    await tester.pumpWidget(_appWithCalmSetupComplete(true));
    await tester.pumpAndSettle();

    expect(find.text("We're All In This Together"), findsOneWidget);
    expect(find.textContaining("Today's needs"), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
  });

  testWidgets('Tapping Calm opens the Calm screen', (tester) async {
    await tester.pumpWidget(_appWithCalmSetupComplete(true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();

    expect(
      find.text('Lower the demand. One thing at a time.'),
      findsOneWidget,
    );
  });
}

Widget _appWithCalmSetupComplete(bool setupComplete) {
  return buildTestApp(calmSetupComplete: setupComplete);
}
