import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Real platform implementation of [NotificationService], wrapping
/// `flutter_local_notifications`.
///
/// Design choices:
///
/// * All of our medication reminders go into a single Android channel
///   id ([_channelId]). There's no meaningful priority difference
///   between, say, a morning dose and an evening dose — they're all
///   "dose reminder".
/// * iOS uses `DateTimeComponents.time` for daily reminders and
///   `DateTimeComponents.dayOfWeekAndTime` for weekly reminders so the
///   OS handles the recurrence for us. That way the reconciler never
///   needs to re-fire on a timer.
/// * We schedule at the device's *local* wall time, not UTC: "take at
///   8am" should mean 8am wherever the user wakes up. We set the
///   timezone on first init so `tz.TZDateTime` resolves correctly.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  /// Channel id shared by all reminders. Changing this value orphans
  /// any notifications the user had scheduled, so keep it stable.
  static const String _channelId = 'medication_reminders';

  /// Category identifier for reminder-style notifications. Reserved
  /// for a future PR that will attach Taken / Snooze actions to it.
  static const String _categoryId = 'MEDICATION_REMINDER';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone database is bundled by the `timezone` package; it
    // needs loading exactly once per process.
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception catch (e, st) {
      // If for some reason we can't resolve the device timezone,
      // UTC is still a sane fallback — reminders will fire, just
      // possibly at a surprising local time. Worth logging, not
      // worth crashing startup over.
      debugPrint('LocalNotificationService: timezone fallback to UTC ($e)');
      debugPrintStack(stackTrace: st);
      tz.setLocalLocation(tz.UTC);
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // We request permissions explicitly via requestPermission(),
        // not during init — initialising shouldn't surprise the user
        // with a system prompt.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(_categoryId),
        ],
      ),
    );

    await _plugin.initialize(settings: initSettings);
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
      // same `false` once the user has interacted. Callers rely on
      // `requestPermission` being safe to re-call, so treating this
      // as `denied` is fine — the banner will disappear after the
      // first grant and the "turn on reminders" button is the only
      // thing that changes state.
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
  Future<Set<int>> pendingReminderIds() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return {for (final p in pending) p.id};
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
        // interruptionLevel.timeSensitive would bypass Focus modes,
        // but that's opinionated — the user may well want Focus to
        // suppress meds during sleep. Leave it at the default
        // `active` and let users opt in via iOS Settings.
      ),
    );

    final firstFire = _nextFireTime(
      weekday: reminder.weekday,
      time: reminder.time,
    );
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: firstFire,
      notificationDetails: notificationDetails,
      // Inexact-while-idle is fine for the low-volume / daily nature
      // of meds and doesn't require the Android 12+ "alarms &
      // reminders" special permission that exact schedules trigger.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: reminder.weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: reminder.medicationId,
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

  /// Compute the next wall-clock instant the reminder should fire.
  ///
  /// `zonedSchedule` requires a concrete first-fire timestamp even when
  /// the notification is declared recurring via
  /// `matchDateTimeComponents`. For a daily reminder we pick today at
  /// the given time if still in the future, else tomorrow. For a
  /// weekly reminder we advance to the next occurrence of the given
  /// weekday.
  tz.TZDateTime _nextFireTime({
    required ScheduledTime time,
    int? weekday,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (weekday == null) {
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    // ISO weekday matches `DateTime.weekday` (1..7, Mon..Sun).
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}

/// App-wide [NotificationService]. The real implementation is the
/// default; tests override this provider with an in-memory fake.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});
