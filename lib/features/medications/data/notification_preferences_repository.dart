import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';

/// Persists [NotificationPreferences] to device-local storage.
///
/// Uses `SharedPreferences` rather than the encrypted Drift DB because
/// these values are (a) not PII, (b) read at startup before any
/// Person's key is available, and (c) genuinely per-device (what
/// nag cadence I want on my phone has nothing to do with what my
/// partner wants on theirs). Phase 2 sync does NOT sync these.
///
/// The repository is intentionally stateless: every read fetches from
/// SharedPreferences. Callers that need reactivity should either
/// re-read after calling [save] or wrap it in a provider that
/// invalidates on write.
abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> load();
  Future<void> save(NotificationPreferences prefs);
}

/// Default [NotificationPreferencesRepository] backed by
/// `SharedPreferences`. Values are clamped on both read and write so
/// a hand-edited prefs plist or a stale format can never make the
/// scheduler misbehave.
class SharedPreferencesNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  SharedPreferencesNotificationPreferencesRepository({
    required Future<SharedPreferences> Function() preferencesLoader,
  }) : _load = preferencesLoader;

  /// Injected so tests can supply a `SharedPreferences.setMockInitialValues`
  /// instance without having to initialise the real plugin.
  final Future<SharedPreferences> Function() _load;

  static const String _intervalKey = 'notif.nag.intervalMinutes';
  static const String _capKey = 'notif.nag.cap';

  @override
  Future<NotificationPreferences> load() async {
    final prefs = await _load();
    final interval = prefs.getInt(_intervalKey) ??
        NotificationPreferences.defaultNagIntervalMinutes;
    final cap = prefs.getInt(_capKey) ?? NotificationPreferences.defaultNagCap;
    return NotificationPreferences(
      nagIntervalMinutes: _clampInterval(interval),
      nagCap: _clampCap(cap),
    );
  }

  @override
  Future<void> save(NotificationPreferences prefs) async {
    final sp = await _load();
    await sp.setInt(_intervalKey, _clampInterval(prefs.nagIntervalMinutes));
    await sp.setInt(_capKey, _clampCap(prefs.nagCap));
  }

  static int _clampInterval(int v) => v.clamp(
        NotificationPreferences.minNagIntervalMinutes,
        NotificationPreferences.maxNagIntervalMinutes,
      );

  static int _clampCap(int v) => v.clamp(0, NotificationPreferences.maxNagCap);
}

/// App-wide [NotificationPreferencesRepository]. Tests override to
/// supply an in-memory fake.
final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return SharedPreferencesNotificationPreferencesRepository(
    preferencesLoader: SharedPreferences.getInstance,
  );
});

/// Reactive view of the currently-saved notification preferences.
///
/// Invalidate after writing via [NotificationPreferencesRepository.save]
/// to have listeners (e.g. the reconciler) pick up the new values.
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final repo = ref.watch(notificationPreferencesRepositoryProvider);
  return repo.load();
});
