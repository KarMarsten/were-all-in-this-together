import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/data/notification_preferences_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';
import 'package:were_all_in_this_together/features/settings/ui/notification_settings_screen.dart';

/// In-memory [NotificationPreferencesRepository] — lets the widget
/// test verify save, load, and invalidation without touching
/// shared_preferences.
class _FakeRepo implements NotificationPreferencesRepository {
  _FakeRepo({NotificationPreferences? initial})
      : _current = initial ?? const NotificationPreferences();

  NotificationPreferences _current;
  int saveCount = 0;

  @override
  Future<NotificationPreferences> load() async => _current;

  @override
  Future<void> save(NotificationPreferences prefs) async {
    _current = prefs;
    saveCount++;
  }
}

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: NotificationSettingsScreen()),
    );

/// Scroll the list until [finder] is visible, then pump. `ensureVisible`
/// on its own doesn't play well with nested `SafeArea > ListView`
/// layouts in `flutter_test` — it computes a position but doesn't
/// actually trigger the scroll animation. Manually dragging the list
/// is the reliable alternative for widget tests.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView),
    const Offset(0, -100),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows loading then renders defaults', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _wrap([
        notificationPreferencesRepositoryProvider.overrideWithValue(repo),
      ]),
    );

    // First frame: FutureProvider is still loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Reminder nagging'), findsOneWidget);
    // Default cap = 3.
    expect(find.textContaining('3 retries'), findsWidgets);
    // Default interval (10 min) is one of the choice chips.
    expect(find.widgetWithText(ChoiceChip, '10 min'), findsOneWidget);
  });

  testWidgets('Save button is disabled until the draft diverges',
      (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _wrap([
        notificationPreferencesRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    final saveBtn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveBtn.onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, '30 min'));
    await tester.pumpAndSettle();

    final dirtyBtn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(dirtyBtn.onPressed, isNotNull);
  });

  testWidgets('saving writes through the repo and clears dirty state',
      (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _wrap([
        notificationPreferencesRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '30 min'));
    await tester.pumpAndSettle();

    // Save button can fall below the viewport — scroll it in first.
    await _scrollTo(tester, find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 1);
    final saved = await repo.load();
    expect(saved.nagIntervalMinutes, 30);

    // Snackbar confirms + save button goes idle again.
    expect(find.text('Saved.'), findsOneWidget);
    final idleBtn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(idleBtn.onPressed, isNull);
  });

  testWidgets('Reset to defaults reverts the form', (tester) async {
    final repo = _FakeRepo(
      initial: const NotificationPreferences(
        nagIntervalMinutes: 60,
        nagCap: 5,
      ),
    );
    await tester.pumpWidget(
      _wrap([
        notificationPreferencesRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '1 hour'), findsOneWidget);

    await _scrollTo(tester, find.text('Reset to defaults'));
    await tester.tap(find.text('Reset to defaults'));
    await tester.pumpAndSettle();

    // 10 min is the default; after reset that chip should be selected.
    final selected = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '10 min'),
    );
    expect(selected.selected, isTrue);
  });
}
