import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// One medication plus the display name of the Person who owns it.
///
/// The reconciler doesn't read the Person repository directly — it
/// takes this already-resolved pair so the caller controls batching
/// and caching. That also keeps the reconciler synchronous in spirit:
/// no I/O beyond the notification service itself.
class OwnedMedication {
  const OwnedMedication({
    required this.medication,
    required this.personDisplayName,
  });

  final Medication medication;
  final String personDisplayName;
}

/// Diff-based sync between the app's medications and the OS's pending
/// notification queue.
///
/// Strategy:
///
/// 1. Walk the input meds, expand each reminder-eligible schedule into
///    a set of [ScheduledReminder]s (the *desired* set).
/// 2. Ask the service for its *pending* ids.
/// 3. Cancel every pending id that isn't in desired.
/// 4. Schedule every desired id that isn't in pending.
///
/// `ScheduledReminder.id` is a deterministic hash of
/// `{medicationId, weekday, time}`, so unchanged reminders across
/// reconciliation passes have stable ids — they neither get cancelled
/// nor re-scheduled.
class ReminderReconciler {
  ReminderReconciler({required NotificationService service})
      : _service = service;

  final NotificationService _service;

  /// Reconcile against the full medication set. Intended to be called
  /// on every change: app start, medication create/update/archive, and
  /// Person create/rename so titles stay correct.
  ///
  /// Returns the reminders that ended up scheduled (useful for logging
  /// and for tests).
  Future<List<ScheduledReminder>> reconcile(
    List<OwnedMedication> meds,
  ) async {
    // If the user hasn't granted permission, scheduling is a no-op
    // from the user's perspective (nothing will be delivered). We
    // still reconcile so the pending queue is correct the moment
    // they grant — avoids a race where they grant and immediately
    // expect reminders to appear.
    final desired = <ScheduledReminder>[];
    for (final owned in meds) {
      desired.addAll(_expand(owned));
    }
    final desiredById = <int, ScheduledReminder>{
      for (final r in desired) r.id: r,
    };

    final pending = await _service.pendingReminderIds();

    for (final id in pending) {
      if (!desiredById.containsKey(id)) {
        await _service.cancelReminder(id);
      }
    }
    for (final entry in desiredById.entries) {
      if (!pending.contains(entry.key)) {
        await _service.scheduleReminder(entry.value);
      }
    }

    return desiredById.values.toList();
  }

  /// Expand one medication into zero or more reminders.
  ///
  /// Rules:
  ///
  /// * Archived meds: zero reminders.
  /// * `ScheduleKind.asNeeded`: zero reminders.
  /// * Missing times: zero reminders (even if days are chosen) —
  ///   `MedicationSchedule.isReminderEligible` returns false and we
  ///   respect it.
  /// * `daily`: one reminder per time, with `weekday` = null so the
  ///   OS treats it as a daily recurrence.
  /// * `weekly`: `days × times` reminders, each with a concrete
  ///   weekday.
  Iterable<ScheduledReminder> _expand(OwnedMedication owned) sync* {
    final med = owned.medication;
    if (med.deletedAt != null) return;
    if (!med.schedule.isReminderEligible) return;

    switch (med.schedule.kind) {
      case ScheduleKind.asNeeded:
        return;
      case ScheduleKind.daily:
        for (final t in med.schedule.times) {
          yield ScheduledReminder(
            medicationId: med.id,
            personId: med.personId,
            medicationName: med.name,
            personDisplayName: owned.personDisplayName,
            time: t,
            dose: med.dose,
          );
        }
      case ScheduleKind.weekly:
        for (final day in med.schedule.days) {
          for (final t in med.schedule.times) {
            yield ScheduledReminder(
              medicationId: med.id,
              personId: med.personId,
              medicationName: med.name,
              personDisplayName: owned.personDisplayName,
              time: t,
              weekday: day,
              dose: med.dose,
            );
          }
        }
    }
  }
}
