import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/notifications/appointment_reminder.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/notifications/appointment_reminder_reconciler.dart';

import '../../helpers/fake_notification_service.dart';

/// Fixed "now" used by every test. Mid-morning UTC so arithmetic
/// with scheduled-at / lead doesn't accidentally cross a day
/// boundary in the reader's head.
final DateTime _fixedNow = DateTime.utc(2030, 1, 7, 10);

Appointment _appt({
  required String id,
  required DateTime scheduledAt,
  String personId = 'p1',
  String title = 'Visit',
  int? reminderLeadMinutes,
  DateTime? deletedAt,
  String? location,
}) {
  final created = DateTime.utc(2030);
  return Appointment(
    id: id,
    personId: personId,
    title: title,
    scheduledAt: scheduledAt,
    createdAt: created,
    updatedAt: created,
    reminderLeadMinutes: reminderLeadMinutes,
    deletedAt: deletedAt,
    location: location,
  );
}

OwnedAppointment _owned(
  Appointment appt, {
  String personDisplayName = 'Alex',
}) =>
    OwnedAppointment(
      appointment: appt,
      personDisplayName: personDisplayName,
    );

AppointmentReminderReconciler _reconciler(
  FakeNotificationService service, {
  DateTime? now,
}) {
  final when = now ?? _fixedNow;
  return AppointmentReminderReconciler(
    service: service,
    clock: () => when,
  );
}

void main() {
  late FakeNotificationService service;

  setUp(() {
    service = FakeNotificationService();
  });

  test('schedules one reminder per eligible appointment', () async {
    final reconciler = _reconciler(service);
    final appt = _appt(
      id: 'a1',
      scheduledAt: _fixedNow.add(const Duration(hours: 2)),
      reminderLeadMinutes: 30,
      location: 'Clinic A',
    );

    final scheduled = await reconciler.reconcile(
      appointments: [_owned(appt, personDisplayName: 'Sam')],
    );

    expect(scheduled, hasLength(1));
    expect(service.scheduledAppointments, hasLength(1));
    final reminder = service.scheduledAppointments.single;
    expect(reminder.appointmentId, 'a1');
    expect(reminder.personDisplayName, 'Sam');
    expect(
      reminder.fireAt,
      _fixedNow.add(const Duration(hours: 1, minutes: 30)),
    );
    expect(reminder.leadMinutes, 30);
    expect(reminder.location, 'Clinic A');
  });

  test('skips appointments without a reminder lead', () async {
    final reconciler = _reconciler(service);
    final appt = _appt(
      id: 'a1',
      scheduledAt: _fixedNow.add(const Duration(hours: 2)),
      // reminderLeadMinutes: null
    );

    await reconciler.reconcile(appointments: [_owned(appt)]);

    expect(service.scheduledAppointments, isEmpty);
  });

  test('skips archived appointments', () async {
    final reconciler = _reconciler(service);
    final appt = _appt(
      id: 'a1',
      scheduledAt: _fixedNow.add(const Duration(hours: 2)),
      reminderLeadMinutes: 30,
      deletedAt: _fixedNow.subtract(const Duration(minutes: 5)),
    );

    await reconciler.reconcile(appointments: [_owned(appt)]);

    expect(service.scheduledAppointments, isEmpty);
  });

  test('skips appointments whose fireAt is not strictly in the future',
      () async {
    final reconciler = _reconciler(service);
    // fireAt = scheduledAt - lead = _fixedNow exactly; must be skipped.
    final sameInstant = _appt(
      id: 'sameInstant',
      scheduledAt: _fixedNow.add(const Duration(minutes: 30)),
      reminderLeadMinutes: 30,
    );
    // fireAt in the past.
    final alreadyPast = _appt(
      id: 'past',
      scheduledAt: _fixedNow.add(const Duration(minutes: 10)),
      reminderLeadMinutes: 30,
    );

    await reconciler.reconcile(
      appointments: [_owned(sameInstant), _owned(alreadyPast)],
    );

    expect(service.scheduledAppointments, isEmpty);
  });

  test('cancels pending appointment reminders no longer desired', () async {
    final reconciler = _reconciler(service);
    // Pre-seed a pending reminder for an appointment that is about
    // to be archived in the desired set.
    final stale = AppointmentReminder(
      appointmentId: 'gone',
      personId: 'p1',
      personDisplayName: 'Alex',
      title: 'Cancelled',
      scheduledAt: _fixedNow.add(const Duration(hours: 3)),
      fireAt: _fixedNow.add(const Duration(hours: 2)),
      leadMinutes: 60,
    );
    await service.scheduleAppointmentReminder(stale);
    expect(service.scheduledAppointments, hasLength(1));

    await reconciler.reconcile(appointments: const []);

    expect(service.scheduledAppointments, isEmpty);
    expect(service.cancelCalls, contains(stale.id));
  });

  test('does not touch pending medication reminders', () async {
    // The medication reconciler has its own bucket. This reconciler
    // must only diff the appointment-pending set — otherwise adding
    // appointment support would cancel every med nag in flight.
    final medReminder = ScheduledReminder(
      medicationId: 'med-1',
      personId: 'p1',
      medicationName: 'Zinc',
      personDisplayName: 'Alex',
      scheduledAt: _fixedNow.add(const Duration(hours: 1)),
      fireAt: _fixedNow.add(const Duration(hours: 1)),
      nagIndex: 0,
      totalInChain: 1,
    );
    await service.scheduleReminder(medReminder);
    final reconciler = _reconciler(service);

    await reconciler.reconcile(appointments: const []);

    expect(service.scheduled, [medReminder]);
    expect(service.cancelCalls, isEmpty);
  });

  test('rescheduling the same appointment replaces the OS registration',
      () async {
    final reconciler = _reconciler(service);
    final first = _appt(
      id: 'same',
      scheduledAt: _fixedNow.add(const Duration(hours: 2)),
      reminderLeadMinutes: 30,
      title: 'Initial title',
    );
    await reconciler.reconcile(appointments: [_owned(first)]);
    expect(service.scheduledAppointments, hasLength(1));
    final firstId = service.scheduledAppointments.single.id;

    final updated = first.copyWith(
      scheduledAt: _fixedNow.add(const Duration(hours: 4)),
      title: 'Moved & renamed',
    );
    await reconciler.reconcile(appointments: [_owned(updated)]);

    expect(service.scheduledAppointments, hasLength(1));
    final current = service.scheduledAppointments.single;
    expect(current.id, firstId);
    expect(current.title, 'Moved & renamed');
    expect(
      current.fireAt,
      _fixedNow.add(const Duration(hours: 3, minutes: 30)),
    );
    expect(service.cancelCalls, isEmpty);
  });

  test('covers every Person on the device, not just an "active" one',
      () async {
    // The reconciler is fed a flat list by the sync provider. A
    // regression would be quietly dropping everyone-but-active-
    // Person before calling in — guard against that here.
    final reconciler = _reconciler(service);
    final apptA = _appt(
      id: 'a',
      personId: 'p-alex',
      scheduledAt: _fixedNow.add(const Duration(hours: 2)),
      reminderLeadMinutes: 15,
    );
    final apptB = _appt(
      id: 'b',
      personId: 'p-sam',
      scheduledAt: _fixedNow.add(const Duration(hours: 3)),
      reminderLeadMinutes: 60,
    );

    await reconciler.reconcile(
      appointments: [
        _owned(apptA),
        _owned(apptB, personDisplayName: 'Sam'),
      ],
    );

    expect(service.scheduledAppointments.map((r) => r.appointmentId).toSet(),
        {'a', 'b'});
  });

  test('second reconcile with unchanged input is idempotent', () async {
    final reconciler = _reconciler(service);
    final appt = _appt(
      id: 'a',
      scheduledAt: _fixedNow.add(const Duration(hours: 2)),
      reminderLeadMinutes: 30,
    );
    await reconciler.reconcile(appointments: [_owned(appt)]);
    await reconciler.reconcile(appointments: [_owned(appt)]);

    expect(service.scheduledAppointments, hasLength(1));
    expect(service.cancelCalls, isEmpty);
  });
}
