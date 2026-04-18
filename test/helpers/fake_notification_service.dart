import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

/// Test fake for [NotificationService].
///
/// Records every call so tests can assert on *what* was scheduled /
/// cancelled, not just the end state. Uses a [Map] keyed on reminder
/// id so behaviour matches the real plugin's rule that scheduling the
/// same id twice replaces the first.
class FakeNotificationService implements NotificationService {
  int initializeCalls = 0;
  int requestPermissionCalls = 0;

  /// Drives `permissionStatus()` and the result of `requestPermission()`.
  /// Tests flip this to model the user tapping allow/deny on the iOS
  /// system prompt.
  NotificationPermission permission = NotificationPermission.notDetermined;

  /// What `requestPermission()` should return / transition to. Defaults
  /// to `granted` — most tests don't care about the prompt, they just
  /// want notifications to work.
  NotificationPermission permissionAfterRequest =
      NotificationPermission.granted;

  final Map<int, ScheduledReminder> _scheduled = {};
  final List<ScheduledReminder> scheduleCalls = [];
  final List<int> cancelCalls = [];
  int cancelAllCalls = 0;

  /// Read-only view of what's currently scheduled. Iteration order is
  /// ascending id so assertions have a stable shape.
  List<ScheduledReminder> get scheduled {
    return [
      for (final id in _scheduled.keys.toList()..sort()) _scheduled[id]!,
    ];
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async {
    requestPermissionCalls++;
    return permission = permissionAfterRequest;
  }

  @override
  Future<Set<int>> pendingReminderIds() async => _scheduled.keys.toSet();

  @override
  Future<void> scheduleReminder(ScheduledReminder reminder) async {
    scheduleCalls.add(reminder);
    _scheduled[reminder.id] = reminder;
  }

  @override
  Future<void> cancelReminder(int id) async {
    cancelCalls.add(id);
    _scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    _scheduled.clear();
  }
}
