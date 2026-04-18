import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

/// Coarse-grained permission state, mirroring what iOS reports and what
/// we render in the UI banner.
///
/// Kept to three values instead of exposing iOS's `provisional`,
/// `ephemeral`, etc. because the app's UX only needs to know:
///
/// * Have we ever asked? If not → show "enable reminders" banner.
/// * Did the user say yes? If so → schedule freely.
/// * Did they say no? If so → route them to Settings.
enum NotificationPermission {
  /// User has never been asked, or platform has no concept of
  /// per-app notification permission (older Android).
  notDetermined,

  /// User has said yes; scheduling is allowed.
  granted,

  /// User has said no. Scheduling still "works" (no throw) but nothing
  /// will be delivered. We should tell the user how to re-enable.
  denied,
}

/// Platform-agnostic facade over the OS's local-notification APIs.
///
/// Kept narrow on purpose: the reconciler only needs "schedule these,
/// cancel those, what's pending?" — it does not care about channels,
/// sound files, or any platform-specific flag. All of that is owned by
/// the concrete `LocalNotificationService` implementation.
///
/// This interface also exists so tests can use an in-memory fake
/// without loading the iOS/Android plugins
/// (`flutter_local_notifications` refuses to initialise outside a
/// real app binding).
abstract class NotificationService {
  /// Must be called once during app startup. Safe to call again — the
  /// implementation is idempotent.
  Future<void> initialize();

  /// Current permission state. Cheap to call; implementations should
  /// prefer cached values where the platform allows.
  Future<NotificationPermission> permissionStatus();

  /// Request permission from the user. Returns the *resulting* state,
  /// so callers can branch on the outcome. On iOS this shows the OS
  /// prompt once; subsequent calls resolve from cached state.
  Future<NotificationPermission> requestPermission();

  /// IDs of every reminder we've scheduled that is still pending
  /// delivery. Used by the reconciler as the "current" set to diff
  /// against the desired set.
  Future<Set<int>> pendingReminderIds();

  /// Schedule (or re-schedule) a single reminder. Must be idempotent
  /// on [ScheduledReminder.id]: calling twice with the same id should
  /// leave exactly one reminder scheduled.
  Future<void> scheduleReminder(ScheduledReminder reminder);

  /// Cancel a single previously-scheduled reminder. No-op if the id
  /// is not currently pending.
  Future<void> cancelReminder(int id);

  /// Cancel every reminder this service has scheduled. Only affects
  /// this app's notifications, not system ones.
  Future<void> cancelAll();
}
