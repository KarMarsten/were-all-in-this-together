import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/notifications/local_notification_service.dart';
import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/notifications/appointment_reminder_reconciler.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

/// Flat list of every upcoming appointment on this device, paired
/// with the display name of its owning Person.
///
/// "Upcoming" means scheduled at-or-after `now` and not archived —
/// the same filter the list screen uses, so both stay consistent.
/// Reminders are scoped to the whole roster (not just the active
/// Person) because a parent managing a child's specialist visit
/// needs the alert regardless of which Person is currently selected
/// in the UI.
final allUpcomingAppointmentsProvider =
    FutureProvider<List<OwnedAppointment>>((ref) async {
  final people = await ref.watch(peopleListProvider.future);
  final repo = ref.watch(appointmentRepositoryProvider);
  final result = <OwnedAppointment>[];
  for (final person in people) {
    final appts = await repo.listUpcomingForPerson(person.id);
    for (final appt in appts) {
      result.add(
        OwnedAppointment(
          appointment: appt,
          personDisplayName: person.displayName,
        ),
      );
    }
  }
  return result;
});

/// Long-lived provider that reconciles appointment reminders with
/// the OS queue whenever the source list changes.
///
/// Kept narrow: unlike the medication sync there are no dose logs,
/// no nag preferences, no drain-queue — an appointment either has
/// a reminder or it doesn't, and its `fireAt` is fully determined
/// by `scheduledAt - reminderLeadMinutes`. The only input that can
/// change that is the appointment row itself.
///
/// This remains available for focused tests and future long-lived sync flows,
/// but the app no longer watches it at startup because iOS pending-notification
/// reads can make launch feel blocked.
final appointmentReminderSyncProvider = Provider<void>((ref) {
  final reconciler = AppointmentReminderReconciler(
    service: ref.watch(notificationServiceProvider),
  );

  ref.listen<AsyncValue<List<OwnedAppointment>>>(
    allUpcomingAppointmentsProvider,
    (_, _) => _maybeReconcile(ref, reconciler),
    fireImmediately: true,
  );
});

void _maybeReconcile(
  Ref ref,
  AppointmentReminderReconciler reconciler,
) {
  final appts = ref.read(allUpcomingAppointmentsProvider);
  if (appts is! AsyncData<List<OwnedAppointment>>) return;

  unawaited(_safeReconcile(reconciler: reconciler, appointments: appts.value));
}

/// Reconcile appointment reminders once, without keeping a listener alive.
///
/// Used after appointment save/archive/restore instead of app startup so iOS
/// notification maintenance never competes with the first interactive frame.
Future<void> reconcileAppointmentRemindersOnce(WidgetRef ref) async {
  final reconciler = AppointmentReminderReconciler(
    service: ref.read(notificationServiceProvider),
  );
  try {
    final appointments = await ref.read(allUpcomingAppointmentsProvider.future);
    await _safeReconcile(
      reconciler: reconciler,
      appointments: appointments,
    );
  } on Object catch (error, st) {
    debugPrint('appointmentReminderSync: one-shot reconcile failed ($error)');
    debugPrintStack(stackTrace: st);
  }
}

Future<void> _safeReconcile({
  required AppointmentReminderReconciler reconciler,
  required List<OwnedAppointment> appointments,
}) async {
  try {
    await reconciler.reconcile(appointments: appointments);
  } on Object catch (error, st) {
    debugPrint('appointmentReminderSync: reconcile failed ($error)');
    debugPrintStack(stackTrace: st);
  }
}
