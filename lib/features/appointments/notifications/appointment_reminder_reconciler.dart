import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/core/notifications/appointment_reminder.dart';
import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';

/// One appointment plus the display name of the Person who owns it.
///
/// Mirrors `OwnedMedication` in the medication reconciler — the
/// reconciler takes already-joined data rather than reading the
/// People repository itself, so the caller controls batching.
@immutable
class OwnedAppointment {
  const OwnedAppointment({
    required this.appointment,
    required this.personDisplayName,
  });

  final Appointment appointment;
  final String personDisplayName;
}

/// Diff-based sync between the app's appointments and the OS's
/// pending notification queue, restricted to appointment reminders.
///
/// Logic, kept deliberately simpler than the medication reconciler:
///
/// 1. Filter to appointments that **should** fire a reminder:
///    * Not archived (`deletedAt == null`).
///    * Have a `reminderLeadMinutes` configured.
///    * `fireAt = scheduledAt - leadMinutes` is still in the future.
/// 2. Emit one [AppointmentReminder] per qualifying appointment.
///    The reminder id is derived from `appointmentId` alone — same
///    id across edits means "reschedule" is an idempotent overwrite
///    on the OS side.
/// 3. Diff desired ids against the service's
///    [NotificationService.pendingAppointmentReminderIds] bucket.
///    Cancel anything pending-but-not-desired; (re)schedule
///    everything desired so a changed time or lead overwrites the
///    previous registration.
///
/// Because every desired reminder is always re-scheduled the
/// reconciler is self-healing: an appointment that moves by an
/// hour simply replaces its own OS registration on the next
/// reconcile pass.
class AppointmentReminderReconciler {
  AppointmentReminderReconciler({
    required NotificationService service,
    DateTime Function()? clock,
  })  : _service = service,
        _clock = clock ?? DateTime.now;

  final NotificationService _service;
  final DateTime Function() _clock;

  /// Reconcile against the full set of known appointments. Returns
  /// the reminders that ended up scheduled (useful for logging and
  /// tests).
  Future<List<AppointmentReminder>> reconcile({
    required List<OwnedAppointment> appointments,
  }) async {
    final now = _clock().toUtc();

    final desired = <AppointmentReminder>[];
    for (final owned in appointments) {
      final appt = owned.appointment;
      if (appt.deletedAt != null) continue;
      final lead = appt.reminderLeadMinutes;
      if (lead == null) continue;

      final scheduledUtc = appt.scheduledAt.toUtc();
      final fireAt = scheduledUtc.subtract(Duration(minutes: lead));
      if (!fireAt.isAfter(now)) {
        // iOS can't schedule in the past; an alert that would fire
        // "now" for an already-started visit is noise anyway.
        continue;
      }

      desired.add(
        AppointmentReminder(
          appointmentId: appt.id,
          personId: appt.personId,
          personDisplayName: owned.personDisplayName,
          title: appt.title,
          scheduledAt: scheduledUtc,
          fireAt: fireAt,
          location: appt.location,
          leadMinutes: lead,
        ),
      );
    }

    final desiredById = <int, AppointmentReminder>{
      for (final r in desired) r.id: r,
    };

    final pending = await _service.pendingAppointmentReminderIds();

    for (final id in pending) {
      if (!desiredById.containsKey(id)) {
        await _service.cancelReminder(id);
      }
    }
    // Always (re)schedule every desired reminder — the platform
    // treats a same-id schedule as "replace", so this is how a
    // moved appointment or an updated title propagates to already-
    // pending entries without a separate change-detection step.
    for (final reminder in desiredById.values) {
      await _service.scheduleAppointmentReminder(reminder);
    }

    return desiredById.values.toList();
  }
}
