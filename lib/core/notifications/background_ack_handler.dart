import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:were_all_in_this_together/core/notifications/notification_action_ids.dart';
import 'package:were_all_in_this_together/core/notifications/pending_ack_queue.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

/// Foreground handler: runs in the main isolate when a notification
/// response arrives while the app is alive.
///
/// We still route through the pending-ACK queue rather than writing
/// to the Drift DB directly. Benefits:
///
/// * Single code path shared with the background handler — one place
///   to change the shape of a queued ACK, one place to test.
/// * The foreground handler runs *before* Riverpod providers from a
///   newly-opened Flutter root may have finished initialising. Writing
///   to the queue is guaranteed safe; touching a provider is not.
///
/// The drainer (triggered on app foreground / resume by
/// `ReminderSyncController`) is the actual writer of `DoseLog` rows.
@pragma('vm:entry-point')
Future<void> onForegroundNotificationResponse(
  NotificationResponse response,
) async {
  await _enqueueAckFromResponse(response, source: 'foreground');
}

/// Background handler: runs in a short-lived isolate spawned by
/// `flutter_local_notifications` when the user taps an action while
/// the app is not in the foreground.
///
/// This isolate has:
/// * No Riverpod, no Drift connection, no Person encryption keys.
/// * Working plugin channels for `flutter_local_notifications` and
///   `shared_preferences` (both packages ship with isolate support).
///
/// So we do the minimum two things that genuinely need to happen at
/// ACK time:
///
/// 1. **Cancel the remaining nag chain** for this dose instance, so
///    the user doesn't keep getting pinged for something they've
///    already acted on.
/// 2. **Enqueue the ACK** to shared preferences. The next time the
///    app is opened, [PendingAckQueue] drains it and writes an
///    encrypted `DoseLog` row.
///
/// Marked `@pragma('vm:entry-point')` so AOT compilation keeps the
/// function alive — the VM can't see that the plugin calls it by
/// symbol.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  await _enqueueAckFromResponse(response, source: 'background');

  // Cancel the chain after enqueueing. If cancellation fails (e.g.
  // the user disabled notifications between scheduling and tapping),
  // we still want the queued ACK to survive so the dose log shows up
  // after next launch.
  await _cancelSiblingsSafely(response);
}

Future<void> _enqueueAckFromResponse(
  NotificationResponse response, {
  required String source,
}) async {
  final outcome = _outcomeForAction(response.actionId);
  if (outcome == null) {
    // Body tap or unknown action id. Body taps bring the app to the
    // front via the OS — the Today screen renders the log status
    // when the user gets there, so no queue entry needed.
    return;
  }

  // Appointment reminders have no action buttons, so an actionId is
  // inherently a medication thing. `ReminderPayload.tryDecode` also
  // rejects non-`med` payload kinds, so this double-gate makes the
  // handler robust even if a future reminder family ever sprouts
  // Taken / Skip-shaped actions.
  final payload = ReminderPayload.tryDecode(response.payload);
  if (payload == null) {
    debugPrint(
      'notifAck: $source ACK with unrecognised payload, dropping '
      '(actionId=${response.actionId}, payload=${response.payload})',
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await PendingAckQueue(prefs).enqueue(
    PendingAck(
      medicationId: payload.medicationId,
      personId: payload.personId,
      scheduledAtUtcMs: payload.scheduledAtUtcMs,
      outcome: outcome,
      ackedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      source: source,
    ),
  );
}

Future<void> _cancelSiblingsSafely(NotificationResponse response) async {
  final payload = ReminderPayload.tryDecode(response.payload);
  if (payload == null) return;

  try {
    final plugin = FlutterLocalNotificationsPlugin();
    for (final id in payload.siblingIds) {
      await plugin.cancel(id: id);
    }
  } on Object catch (e, st) {
    // Cancelling is best-effort — don't let a plugin hiccup lose
    // the ACK we've already queued.
    debugPrint('notifAck: failed to cancel nag chain ($e)');
    debugPrintStack(stackTrace: st);
  }
}

/// Map an OS action id to the dose outcome string we store in the
/// queue. Null means "not a Taken/Skip tap" — e.g. a body tap.
///
/// The return type is `String?` rather than a typed enum because
/// the queue entry is later consumed by code that loads the
/// `DoseOutcome` enum; keeping the wire value as a plain string
/// avoids importing medication-feature code into a core notification
/// handler.
String? _outcomeForAction(String? actionId) {
  switch (actionId) {
    case NotificationActionIds.taken:
      return 'taken';
    case NotificationActionIds.skip:
      return 'skipped';
    default:
      return null;
  }
}
