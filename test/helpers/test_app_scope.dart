import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` is not exported from the main flutter_riverpod barrel in 3.x.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/core/notifications/local_notification_service.dart';
import 'package:were_all_in_this_together/features/medications/data/notification_preferences_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';
import 'package:were_all_in_this_together/features/medications/notifications/pending_ack_drainer.dart';
import 'package:were_all_in_this_together/features/people/data/active_person_preference.dart';

import 'fake_notification_service.dart';
import 'in_memory_active_person_preference.dart';
import 'in_memory_key_storage.dart';

/// Wraps the app in a [ProviderScope] with test doubles for every provider
/// that would otherwise touch a platform channel: [AppDatabase],
/// [KeyStorage], and [ActivePersonPreference].
///
/// Each call builds fresh state so tests don't leak into each other.
Widget buildTestApp({
  List<Override> extraOverrides = const [],
  String? initialActivePersonId,
}) {
  // SharedPreferences plugin channel is not wired in `flutter test`;
  // `setMockInitialValues` installs an in-memory backend so anything
  // that touches shared_preferences (e.g. the pending-ACK drainer,
  // notification prefs repo) behaves predictably rather than hanging.
  SharedPreferences.setMockInitialValues(<String, Object>{});

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      keyStorageProvider.overrideWith((_) => InMemoryKeyStorage()),
      activePersonPreferenceProvider.overrideWith(
        (_) => InMemoryActivePersonPreference(initialId: initialActivePersonId),
      ),
      // The real notification service wraps flutter_local_notifications,
      // which hits a platform channel the moment it's touched. A fake
      // keeps widget tests hermetic without giving up coverage of the
      // reminder-sync plumbing.
      notificationServiceProvider
          .overrideWith((_) => FakeNotificationService()),
      // Notification prefs normally round-trip through SharedPreferences;
      // in widget tests we resolve synchronously with defaults so the
      // reconciler fires without waiting on a mock plugin.
      notificationPreferencesProvider
          .overrideWith((_) async => const NotificationPreferences()),
      // The drainer is wired into the App's lifecycle observer; with a
      // real AppDatabase but no real Person keys it would no-op anyway,
      // but an explicit no-op keeps widget tests from flaking on the
      // post-frame drain call.
      pendingAckDrainerProvider.overrideWith((_) => _NoopAckDrainer()),
      ...extraOverrides,
    ],
    child: const App(),
  );
}

class _NoopAckDrainer implements PendingAckDrainer {
  @override
  Future<int> drain() async => 0;
}
