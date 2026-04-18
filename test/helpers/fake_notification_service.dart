import 'package:were_all_in_this_together/core/notifications/appointment_reminder.dart';
import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

/// Test fake for [NotificationService].
///
/// Records every call so tests can assert on *what* was scheduled /
/// cancelled, not just the end state. Uses a [Map] keyed on reminder
/// id so behaviour matches the real plugin's rule that scheduling
/// the same id twice replaces the first.
///
/// Medication and appointment reminders live in separate maps to
/// mirror the payload-kind filtering the real service does on the
/// platform's pending queue.
class FakeNotificationService implements NotificationService {
  int initializeCalls = 0;
  int requestPermissionCalls = 0;

  /// Drives `permissionStatus()` and the result of
  /// `requestPermission()`. Tests flip this to model the user
  /// tapping allow/deny on the iOS system prompt.
  NotificationPermission permission = NotificationPermission.notDetermined;

  /// What `requestPermission()` should return / transition to.
  /// Defaults to `granted` — most tests don't care about the
  /// prompt, they just want notifications to work.
  NotificationPermission permissionAfterRequest =
      NotificationPermission.granted;

  final Map<int, ScheduledReminder> _scheduled = {};
  final Map<int, AppointmentReminder> _scheduledAppointments = {};
  final List<ScheduledReminder> scheduleCalls = [];
  final List<AppointmentReminder> appointmentScheduleCalls = [];
  final List<int> cancelCalls = [];
  int cancelAllCalls = 0;

  /// Read-only view of what's currently scheduled for medications.
  /// Iteration order is ascending id so assertions have a stable
  /// shape.
  List<ScheduledReminder> get scheduled {
    return [
      for (final id in _scheduled.keys.toList()..sort()) _scheduled[id]!,
    ];
  }

  /// Read-only view of what's currently scheduled for appointments,
  /// again in ascending-id order.
  List<AppointmentReminder> get scheduledAppointments {
    return [
      for (final id in _scheduledAppointments.keys.toList()..sort())
        _scheduledAppointments[id]!,
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
  Future<Set<int>> pendingMedicationReminderIds() async =>
      _scheduled.keys.toSet();

  @override
  Future<Set<int>> pendingAppointmentReminderIds() async =>
      _scheduledAppointments.keys.toSet();

  @override
  Future<void> scheduleReminder(ScheduledReminder reminder) async {
    scheduleCalls.add(reminder);
    _scheduled[reminder.id] = reminder;
  }

  @override
  Future<void> scheduleAppointmentReminder(
    AppointmentReminder reminder,
  ) async {
    appointmentScheduleCalls.add(reminder);
    _scheduledAppointments[reminder.id] = reminder;
  }

  @override
  Future<void> cancelReminder(int id) async {
    cancelCalls.add(id);
    _scheduled.remove(id);
    _scheduledAppointments.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    _scheduled.clear();
    _scheduledAppointments.clear();
  }
}
