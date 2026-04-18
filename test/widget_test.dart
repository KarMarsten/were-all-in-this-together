import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/app.dart';

void main() {
  testWidgets('App boots to home and shows Calm button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text("We're All In This Together"), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
  });

  testWidgets('Tapping Calm opens the Calm screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();

    expect(find.text('One thing at a time.'), findsOneWidget);
  });
}
