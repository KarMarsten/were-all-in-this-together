import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:were_all_in_this_together/core/notifications/appointment_reminder.dart';
import 'package:were_all_in_this_together/core/notifications/background_ack_handler.dart';
import 'package:were_all_in_this_together/core/notifications/notification_action_ids.dart';
import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

/// Real platform implementation of [NotificationService], wrapping
/// `flutter_local_notifications`.
///
/// Design choices:
///
/// * Reminders are **one-shot**: one OS registration per dose
///   instance per nag step. The reconciler tracks the full set and
///   re-schedules a rolling 48-hour window on demand. This is
///   necessary for nag chains (an unacknowledged 08:00 dose can't
///   trigger follow-ups unless those follow-ups were pre-scheduled)
///   and for dose-level ACK (each fires on a distinct `fireAt` so
///   taking the 08:00 pill doesn't cancel the 20:00 one).
/// * Taken and Skip live as **notification actions** on a shared
///   iOS category. Both are declared *without* the `foreground`
///   option so a tap resolves in a short-lived background isolate
///   — the caregiver sees the OS banner collapse, the app does
///   not come to the front.
/// * We schedule at the device's *local* wall time. "Take at 08:00"
///   means 08:00 wherever the user is.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  /// Channel id shared by all medication reminders. Changing this
  /// value orphans any notifications the user had scheduled, so
  /// keep it stable.
  static const String _channelId = 'medication_reminders';

  /// Dedicated channel for appointment reminders. Kept separate so
  /// Android users can mute one family without the other — the
  /// "hey, Dr. Chen in 30 min" alert is low-frequency and usually
  /// welcome even for people who mute medication pings.
  static const String _appointmentChannelId = 'appointment_reminders';

  /// iOS category identifier for medication reminders. Must match
  /// the id Flutter registers with `DarwinNotificationCategory`
  /// below and must match what the AppDelegate declares in native
  /// code, otherwise action buttons silently disappear.
  static const String _categoryId = 'MEDICATION_REMINDER';

  /// iOS category for appointment reminders. No action buttons —
  /// appointments have nothing to ACK in the background, so the
  /// category exists only to keep iOS grouping consistent.
  static const String _appointmentCategoryId = 'APPOINTMENT_REMINDER';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception catch (e, st) {
      // If we can't resolve the device timezone, UTC is a sane
      // fallback — reminders still fire, just possibly at a
      // surprising local time. Log, don't crash startup.
      debugPrint('LocalNotificationService: timezone fallback to UTC ($e)');
      debugPrintStack(stackTrace: st);
      tz.setLocalLocation(tz.UTC);
    }

    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // We request permissions explicitly via requestPermission(),
        // not during init — initialising shouldn't surprise the user
        // with a system prompt.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          // Appointments: no actions. Having a category still lets
          // iOS group these reminders distinctly in the Notification
          // Center and lets a later PR wire category-scoped deep
          // links without a new category registration.
          const DarwinNotificationCategory(_appointmentCategoryId),
          DarwinNotificationCategory(
            _categoryId,
            actions: [
              // `Taken` intentionally not destructive: the user just
              // confirmed they took it, that's a *good* thing.
              // `destructiveHint` is reserved for things like
              // "delete".
              DarwinNotificationAction.plain(
                NotificationActionIds.taken,
                'Taken',
              ),
              // `Skip` isn't destructive either — skipping a dose
              // is a legitimate medical choice ("doctor said skip
              // if you've already taken ibuprofen today"). No
              // foreground option so a tap dismisses silently.
              DarwinNotificationAction.plain(
                NotificationActionIds.skip,
                'Skip',
              ),
            ],
          ),
        ],
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      // Foreground handler runs on the main isolate — lightweight
      // wrapper that just routes the action into the Riverpod-
      // backed drainer.
      onDidReceiveNotificationResponse: onForegroundNotificationResponse,
      // Background handler runs in a disposable isolate without
      // Riverpod. Must be a top-level, `@pragma('vm:entry-point')`
      // function so AOT compilation keeps it alive.
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
    _initialized = true;
  }

  @override
  Future<NotificationPermission> permissionStatus() async {
    await initialize();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final opts = await ios?.checkPermissions();
      if (opts == null) return NotificationPermission.notDetermined;
      if (opts.isAlertEnabled) return NotificationPermission.granted;
      // iOS collapses "never asked" and "explicitly denied" into the
      // same `false` once the user has interacted. Treating it as
      // `denied` is fine — the banner disappears after first grant
      // and the "turn on reminders" button is the only thing that
      // moves state.
      return NotificationPermission.denied;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.areNotificationsEnabled() ?? false;
      return granted
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    return NotificationPermission.notDetermined;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    await initialize();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
      return granted
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    return NotificationPermission.notDetermined;
  }

  @override
  Future<Set<int>> pendingMedicationReminderIds() async =>
      _pendingIdsOfKind(ReminderPayloadKind.medication);

  @override
  Future<Set<int>> pendingAppointmentReminderIds() async =>
      _pendingIdsOfKind(ReminderPayloadKind.appointment);

  /// Inspect pending notifications and return the ids whose payload
  /// matches [kind]. Legacy pre-PR-22 payloads are treated as
  /// medication reminders (see [peekReminderPayloadKind]), so an
  /// upgrade never orphans the user's previously-scheduled nags.
  Future<Set<int>> _pendingIdsOfKind(String kind) async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    final out = <int>{};
    for (final p in pending) {
      final peeked = peekReminderPayloadKind(p.payload);
      if (peeked == kind) out.add(p.id);
    }
    return out;
  }

  @override
  Future<void> scheduleReminder(ScheduledReminder reminder) async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Medication reminders',
        channelDescription: 'Gentle reminders for scheduled doses.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _categoryId,
        // interruptionLevel.timeSensitive would bypass Focus modes
        // but that's opinionated — the user may well want Focus
        // to suppress meds during sleep. Leave it at the default
        // `active` and let users opt in via iOS Settings.
      ),
    );

    final fireAt = tz.TZDateTime.from(reminder.fireAt, tz.local);
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: fireAt,
      notificationDetails: notificationDetails,
      // Inexact-while-idle is fine for the low-volume / daily
      // nature of meds and doesn't require the Android 12+
      // "alarms & reminders" special permission that exact
      // schedules trigger.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.encodePayload(),
    );
  }

  @override
  Future<void> scheduleAppointmentReminder(
    AppointmentReminder reminder,
  ) async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _appointmentChannelId,
        'Appointment reminders',
        channelDescription:
            'Heads-up notifications for upcoming visits and meetings.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _appointmentCategoryId,
      ),
    );

    final fireAt = tz.TZDateTime.from(reminder.fireAt, tz.local);
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.displayTitle,
      body: reminder.body,
      scheduledDate: fireAt,
      notificationDetails: notificationDetails,
      // Same rationale as medication reminders: inexact-while-idle
      // avoids the Android 12+ "alarms & reminders" special
      // permission and is accurate enough for a "heads up, visit
      // in X" alert.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.encodePayload(),
    );
  }

  @override
  Future<void> cancelReminder(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}

/// App-wide [NotificationService]. The real implementation is the
/// default; tests override this provider with an in-memory fake.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});
