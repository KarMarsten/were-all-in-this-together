import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:were_all_in_this_together/features/medications/data/notification_preferences_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';

void main() {
  setUp(() {
    // Fresh in-memory prefs per test so keys don't leak between cases.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('NotificationPreferences model', () {
    test('defaults match the published constants', () {
      const prefs = NotificationPreferences();
      expect(
        prefs.nagIntervalMinutes,
        NotificationPreferences.defaultNagIntervalMinutes,
      );
      expect(prefs.nagCap, NotificationPreferences.defaultNagCap);
    });
  });

  group('SharedPreferencesNotificationPreferencesRepository', () {
    late SharedPreferencesNotificationPreferencesRepository repo;

    setUp(() {
      repo = SharedPreferencesNotificationPreferencesRepository(
        preferencesLoader: SharedPreferences.getInstance,
      );
    });

    test('load returns defaults when nothing has been saved', () async {
      final prefs = await repo.load();
      expect(prefs, const NotificationPreferences());
    });

    test('save → load round-trips exact values', () async {
      await repo.save(
        const NotificationPreferences(nagIntervalMinutes: 30, nagCap: 5),
      );
      final prefs = await repo.load();
      expect(prefs.nagIntervalMinutes, 30);
      expect(prefs.nagCap, 5);
    });

    test('save clamps out-of-range values to the published limits',
        () async {
      await repo.save(
        const NotificationPreferences(
          nagIntervalMinutes: 10000,
          nagCap: 99,
        ),
      );
      final prefs = await repo.load();
      expect(
        prefs.nagIntervalMinutes,
        NotificationPreferences.maxNagIntervalMinutes,
      );
      expect(prefs.nagCap, NotificationPreferences.maxNagCap);
    });

    test('save clamps values below the minimum to min', () async {
      await repo.save(
        const NotificationPreferences(nagIntervalMinutes: 0, nagCap: -1),
      );
      final prefs = await repo.load();
      expect(
        prefs.nagIntervalMinutes,
        NotificationPreferences.minNagIntervalMinutes,
      );
      expect(prefs.nagCap, 0);
    });

    test(
      'load clamps hand-edited out-of-range stored values',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'notif.nag.intervalMinutes': 99999,
          'notif.nag.cap': -4,
        });
        final prefs = await repo.load();
        expect(
          prefs.nagIntervalMinutes,
          NotificationPreferences.maxNagIntervalMinutes,
        );
        expect(prefs.nagCap, 0);
      },
    );
  });
}
