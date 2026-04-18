import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_reconciler.dart';

import '../../helpers/fake_notification_service.dart';

Medication _med({
  required String id,
  required String personId,
  String name = 'Test',
  MedicationSchedule schedule = MedicationSchedule.asNeeded,
  DateTime? deletedAt,
  String? dose,
}) {
  final now = DateTime.utc(2030);
  return Medication(
    id: id,
    personId: personId,
    name: name,
    createdAt: now,
    updatedAt: now,
    dose: dose,
    schedule: schedule,
    deletedAt: deletedAt,
  );
}

OwnedMedication _owned(
  Medication med, {
  String personDisplayName = 'Alex',
}) =>
    OwnedMedication(medication: med, personDisplayName: personDisplayName);

void main() {
  late FakeNotificationService service;
  late ReminderReconciler reconciler;

  setUp(() {
    service = FakeNotificationService();
    reconciler = ReminderReconciler(service: service);
  });

  group('expansion', () {
    test('empty list cancels every pending reminder', () async {
      // Seed a pending reminder that should be swept on reconcile.
      await service.scheduleReminder(
        ScheduledReminder(
          medicationId: 'stale',
          personId: 'p1',
          medicationName: 'Stale',
          personDisplayName: 'Alex',
          time: const ScheduledTime(hour: 8, minute: 0),
        ),
      );
      expect(service.scheduled, hasLength(1));

      final result = await reconciler.reconcile([]);

      expect(result, isEmpty);
      expect(service.scheduled, isEmpty);
    });

    test('asNeeded meds produce zero reminders', () async {
      final med = _med(id: 'm1', personId: 'p1');

      final result = await reconciler.reconcile([_owned(med)]);

      expect(result, isEmpty);
      expect(service.scheduled, isEmpty);
    });

    test('archived meds produce zero reminders', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        deletedAt: DateTime.utc(2030, 1, 2),
      );

      final result = await reconciler.reconcile([_owned(med)]);

      expect(result, isEmpty);
    });

    test('daily schedule with N times produces N reminders', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        name: 'Methylphenidate',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [
            ScheduledTime(hour: 8, minute: 0),
            ScheduledTime(hour: 12, minute: 0),
            ScheduledTime(hour: 20, minute: 30),
          ],
        ),
      );

      final result = await reconciler.reconcile([_owned(med)]);

      expect(result, hasLength(3));
      expect(
        result.map((r) => r.time.toWireString()).toList(),
        containsAll(<String>['08:00', '12:00', '20:30']),
      );
      expect(result.every((r) => r.weekday == null), isTrue);
    });

    test('weekly schedule produces days × times reminders', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.weekly,
          days: {1, 3, 5},
          times: [
            ScheduledTime(hour: 9, minute: 0),
            ScheduledTime(hour: 21, minute: 0),
          ],
        ),
      );

      final result = await reconciler.reconcile([_owned(med)]);

      expect(result, hasLength(6));
      // Each (day, time) pair appears exactly once.
      final pairs = result
          .map((r) => '${r.weekday}@${r.time.toWireString()}')
          .toSet();
      expect(pairs, {
        '1@09:00',
        '1@21:00',
        '3@09:00',
        '3@21:00',
        '5@09:00',
        '5@21:00',
      });
    });

    test(
        'reminder-eligible but empty-times schedule produces nothing '
        '(weekday picked, no time yet)', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.weekly,
          days: {1, 2},
        ),
      );

      final result = await reconciler.reconcile([_owned(med)]);

      expect(result, isEmpty);
    });
  });

  group('diff behaviour', () {
    test(
        'second reconcile with same input does not re-schedule or cancel '
        'anything', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );

      await reconciler.reconcile([_owned(med)]);
      final scheduleCallsAfterFirst = service.scheduleCalls.length;
      final cancelCallsAfterFirst = service.cancelCalls.length;

      await reconciler.reconcile([_owned(med)]);

      // IDs are deterministic, so the reminder id is already in the
      // pending set the second time through — no side effects expected.
      expect(service.scheduleCalls, hasLength(scheduleCallsAfterFirst));
      expect(service.cancelCalls, hasLength(cancelCallsAfterFirst));
    });

    test('removing a med cancels its reminder only', () async {
      final a = _med(
        id: 'a',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );
      final b = _med(
        id: 'b',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 20, minute: 0)],
        ),
      );

      await reconciler.reconcile([_owned(a), _owned(b)]);
      expect(service.scheduled, hasLength(2));

      await reconciler.reconcile([_owned(a)]);

      expect(service.scheduled, hasLength(1));
      expect(service.scheduled.single.medicationId, 'a');
    });

    test('changing a time cancels the old reminder and schedules the new',
        () async {
      final initial = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );
      await reconciler.reconcile([_owned(initial)]);
      final firstId = service.scheduled.single.id;

      final edited = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 9, minute: 0)],
        ),
      );
      await reconciler.reconcile([_owned(edited)]);

      expect(service.scheduled, hasLength(1));
      expect(service.scheduled.single.id, isNot(firstId));
      expect(service.cancelCalls, contains(firstId));
    });
  });

  group('reminder content', () {
    test(
        'title carries Person name and med name so multi-person families '
        'can see whose reminder fired at a glance', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        name: 'Methylphenidate',
        dose: '10mg',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );

      await reconciler.reconcile([_owned(med)]);
      final r = service.scheduled.single;

      expect(r.title, 'Alex · Methylphenidate');
      expect(r.body, contains('10mg'));
    });

    test('missing dose falls back to a generic body', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );

      await reconciler.reconcile([_owned(med)]);

      expect(service.scheduled.single.body, 'Time for a dose.');
    });
  });

  group('ScheduledReminder id stability', () {
    test(
        'two reminders with the same (medicationId, weekday, time) compare '
        'equal and share an id', () {
      final a = ScheduledReminder(
        medicationId: 'med-1',
        personId: 'p1',
        medicationName: 'x',
        personDisplayName: 'Alex',
        time: const ScheduledTime(hour: 8, minute: 0),
        weekday: 3,
      );
      final b = ScheduledReminder(
        medicationId: 'med-1',
        personId: 'p1',
        // Person rename: title would differ but the id must not.
        medicationName: 'x',
        personDisplayName: 'Alexandra',
        time: const ScheduledTime(hour: 8, minute: 0),
        weekday: 3,
      );

      expect(a.id, b.id);
      expect(a, b);
    });

    test('different medication ids produce different reminder ids', () {
      final a = ScheduledReminder(
        medicationId: 'med-1',
        personId: 'p1',
        medicationName: 'x',
        personDisplayName: 'Alex',
        time: const ScheduledTime(hour: 8, minute: 0),
      );
      final b = ScheduledReminder(
        medicationId: 'med-2',
        personId: 'p1',
        medicationName: 'x',
        personDisplayName: 'Alex',
        time: const ScheduledTime(hour: 8, minute: 0),
      );

      expect(a.id, isNot(b.id));
    });

    test('IDs are non-negative 31-bit ints', () {
      final r = ScheduledReminder(
        medicationId: 'med-1',
        personId: 'p1',
        medicationName: 'x',
        personDisplayName: 'Alex',
        time: const ScheduledTime(hour: 8, minute: 0),
      );
      expect(r.id, greaterThanOrEqualTo(0));
      expect(r.id, lessThan(0x80000000));
    });
  });
}
