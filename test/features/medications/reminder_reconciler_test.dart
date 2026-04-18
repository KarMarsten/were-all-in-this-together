import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_reconciler.dart';

import '../../helpers/fake_notification_service.dart';

/// "Now" used by every test — a Monday morning at 07:00 *local*
/// time so a local 08:00 dose is comfortably in the future and the
/// weekday stays Monday regardless of the machine's timezone.
///
/// Using a local wall-clock instant (then `.toUtc()`) keeps the
/// reconciler's local-date expansion stable across CI timezones.
/// A UTC instant would shift the perceived local weekday when
/// CI crosses zones.
final DateTime _fixedLocalNow = DateTime(2030, 1, 7, 7);
final DateTime _fixedNow = _fixedLocalNow.toUtc();

Medication _med({
  required String id,
  required String personId,
  String name = 'Test',
  MedicationSchedule schedule = MedicationSchedule.asNeeded,
  DateTime? deletedAt,
  String? dose,
  int? nagIntervalMinutesOverride,
  int? nagCapOverride,
}) {
  final created = DateTime.utc(2030);
  return Medication(
    id: id,
    personId: personId,
    name: name,
    createdAt: created,
    updatedAt: created,
    dose: dose,
    schedule: schedule,
    deletedAt: deletedAt,
    nagIntervalMinutesOverride: nagIntervalMinutesOverride,
    nagCapOverride: nagCapOverride,
  );
}

OwnedMedication _owned(
  Medication med, {
  String personDisplayName = 'Alex',
}) =>
    OwnedMedication(medication: med, personDisplayName: personDisplayName);

ReminderReconciler _buildReconciler(
  FakeNotificationService service, {
  DateTime? now,
  Duration window = const Duration(hours: 48),
}) {
  final when = now ?? _fixedNow;
  return ReminderReconciler(
    service: service,
    windowDuration: window,
    clock: () => when,
  );
}

/// Default prefs: 10-minute interval, cap of 3 — matches production
/// defaults so tests exercise the same arithmetic the real app runs.
const _defaultPrefs = NotificationPreferences();

/// Daily-at-08:00 schedule used in most tests. 08:00 is chosen to
/// land comfortably after `_fixedNow` (07:00 UTC) so the initial
/// reminder is in the future on the same day.
MedicationSchedule _daily08() => const MedicationSchedule(
      kind: ScheduleKind.daily,
      times: [ScheduledTime(hour: 8, minute: 0)],
    );

void main() {
  late FakeNotificationService service;

  setUp(() {
    service = FakeNotificationService();
  });

  group('reconcile — empty / no-op cases', () {
    test('empty list cancels every pending reminder', () async {
      // Seed a stale reminder the reconciler should sweep.
      await service.scheduleReminder(
        ScheduledReminder(
          medicationId: 'stale',
          personId: 'p1',
          medicationName: 'Stale',
          personDisplayName: 'Alex',
          scheduledAt: _fixedNow.add(const Duration(hours: 2)),
          fireAt: _fixedNow.add(const Duration(hours: 2)),
          nagIndex: 0,
          totalInChain: 1,
        ),
      );
      expect(service.scheduled, hasLength(1));

      final reconciler = _buildReconciler(service);
      final result = await reconciler.reconcile(
        meds: const [],
        preferences: _defaultPrefs,
      );

      expect(result, isEmpty);
      expect(service.scheduled, isEmpty);
    });

    test('asNeeded meds produce zero reminders', () async {
      final med = _med(id: 'm1', personId: 'p1');
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );

      expect(result, isEmpty);
      expect(service.scheduled, isEmpty);
    });

    test('archived meds produce zero reminders', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: _daily08(),
        deletedAt: DateTime.utc(2030),
      );

      final reconciler = _buildReconciler(service);
      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );

      expect(result, isEmpty);
    });

    test('daily schedule with no times produces zero reminders', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(kind: ScheduleKind.daily),
      );
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );

      expect(result, isEmpty);
    });
  });

  group('nag chain', () {
    test(
      'daily med emits one chain (initial + cap nags) per dose in window',
      () async {
        final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
        final reconciler = _buildReconciler(service);

        final result = await reconciler.reconcile(
          meds: [_owned(med)],
          preferences: _defaultPrefs,
        );

        // 48h window, 1 dose/day = 2 dose instances × (1 + cap=3)
        // reminders each = 8 reminders.
        expect(result, hasLength(8));
        expect(service.scheduled, hasLength(8));

        // Check the initial reminder of the first dose: fireAt ==
        // scheduledAt, nagIndex 0, totalInChain 4.
        final firstDay = result.where((r) => r.nagIndex == 0).toList()
          ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
        expect(firstDay, hasLength(2));
        expect(firstDay.first.fireAt, firstDay.first.scheduledAt);
        expect(firstDay.first.totalInChain, 4);
      },
    );

    test('nag follow-ups are spaced by the configured interval', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: const NotificationPreferences(
          nagIntervalMinutes: 15,
          nagCap: 2,
        ),
      );

      final firstDose = result
          .where((r) => r.scheduledAt == result.first.scheduledAt)
          .toList()
        ..sort((a, b) => a.nagIndex.compareTo(b.nagIndex));
      expect(firstDose, hasLength(3));
      expect(
        firstDose[1].fireAt.difference(firstDose[0].fireAt),
        const Duration(minutes: 15),
      );
      expect(
        firstDose[2].fireAt.difference(firstDose[0].fireAt),
        const Duration(minutes: 30),
      );
    });

    test('cap=0 disables nagging — one reminder per dose', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: const NotificationPreferences(nagCap: 0),
      );

      // 2 dose instances in a 48h window, 1 reminder each.
      expect(result, hasLength(2));
      expect(result.every((r) => r.nagIndex == 0), isTrue);
      expect(result.every((r) => r.totalInChain == 1), isTrue);
    });

    test('per-medication override beats global defaults', () async {
      final medA = _med(
        id: 'a',
        personId: 'p1',
        name: 'A',
        schedule: _daily08(),
      );
      final medB = _med(
        id: 'b',
        personId: 'p1',
        name: 'B',
        schedule: _daily08(),
        nagCapOverride: 0,
        nagIntervalMinutesOverride: 5,
      );
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(medA), _owned(medB)],
        preferences: _defaultPrefs,
      );

      final forA = result.where((r) => r.medicationId == 'a').toList();
      final forB = result.where((r) => r.medicationId == 'b').toList();

      // A uses the defaults: 2 × 4 = 8 reminders.
      expect(forA, hasLength(8));
      // B turns nagging off: 2 × 1 = 2 reminders.
      expect(forB, hasLength(2));
      expect(forB.every((r) => r.totalInChain == 1), isTrue);
    });
  });

  group('window', () {
    test('past dose instances are skipped', () async {
      // Med is scheduled daily at 08:00 local; the clock is pinned to
      // 09:00 local on the same day. Today's 08:00 instance is in the
      // past and should be dropped; the next two days' 08:00 are
      // still inside the 48-hour window.
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final clock = DateTime(2030, 1, 7, 9).toUtc();
      final today08 = DateTime(2030, 1, 7, 8).toUtc();
      final reconciler = _buildReconciler(service, now: clock);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );

      // 2 future doses × 4 reminders = 8; today's past dose contributes
      // zero.
      expect(result, hasLength(8));
      expect(
        result.every((r) => r.scheduledAt != today08),
        isTrue,
        reason: "today's past 08:00 dose must not be scheduled",
      );
    });

    test('weekly schedule only fires on selected ISO weekdays', () async {
      // `_fixedNow` is Monday 07:00 UTC; a Wed/Fri schedule should emit
      // nothing in a 48h window (Mon+Tue).
      final med = _med(
        id: 'm1',
        personId: 'p1',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.weekly,
          times: [ScheduledTime(hour: 8, minute: 0)],
          days: {3, 5},
        ),
      );
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );

      expect(result, isEmpty);
    });

    test('already-logged dose is dropped from the desired set', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      // Build the identity for today's 08:00 (the dose the reconciler
      // will emit if we don't intervene). Computed from the local
      // wall-clock calendar of `_fixedLocalNow` so this matches what
      // the reconciler's local-day expansion will produce.
      final today08Local =
          DateTime(_fixedLocalNow.year, _fixedLocalNow.month,
                  _fixedLocalNow.day, 8)
              .toUtc();
      final identity = (
        medicationId: med.id,
        scheduledAtUtcMs: today08Local.millisecondsSinceEpoch,
      );

      final log = DoseLog(
        id: 'log1',
        personId: med.personId,
        medicationId: med.id,
        scheduledAt: today08Local,
        loggedAt: today08Local,
        outcome: DoseOutcome.taken,
        createdAt: today08Local,
        updatedAt: today08Local,
      );

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
        doseLogsByIdentity: {identity: log},
      );

      // Today's chain is suppressed; tomorrow's (4 reminders) still ships.
      expect(result, hasLength(4));
      expect(
        result.every((r) => r.scheduledAt != today08Local),
        isTrue,
      );
    });
  });

  group('diff semantics', () {
    test('second reconcile with same inputs is a no-op', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );
      final firstCalls = service.scheduleCalls.length;

      await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );

      expect(service.scheduleCalls.length, firstCalls,
          reason: 'stable ids should mean no rescheduling on second pass');
      expect(service.cancelCalls, isEmpty);
    });

    test('reducing cap cancels the now-unwanted nag tail', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );
      expect(service.scheduled, hasLength(8));

      await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: const NotificationPreferences(nagCap: 1),
      );

      // 2 doses × (1 + 1) = 4 reminders.
      expect(service.scheduled, hasLength(4));
      // 4 former nag-index=2/3 ids got cancelled.
      expect(service.cancelCalls, hasLength(4));
    });

    test('archiving a med cancels its chains', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: _defaultPrefs,
      );
      expect(service.scheduled, hasLength(8));

      final archived = med.copyWith(deletedAt: DateTime.utc(2030, 1, 7, 6));
      await reconciler.reconcile(
        meds: [_owned(archived)],
        preferences: _defaultPrefs,
      );

      expect(service.scheduled, isEmpty);
      expect(service.cancelCalls, hasLength(8));
    });
  });

  group('reminder metadata', () {
    test('title uses Person display name and medication name', () async {
      final med = _med(
        id: 'm1',
        personId: 'p1',
        name: 'Vitamin D',
        schedule: _daily08(),
      );
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med, personDisplayName: 'Sam')],
        preferences: const NotificationPreferences(nagCap: 0),
      );

      expect(result.first.title, 'Sam · Vitamin D');
    });

    test('siblingIds includes every index in the chain', () async {
      final med = _med(id: 'm1', personId: 'p1', schedule: _daily08());
      final reconciler = _buildReconciler(service);

      final result = await reconciler.reconcile(
        meds: [_owned(med)],
        preferences: const NotificationPreferences(nagCap: 2),
      );

      final firstChain = result
          .where((r) => r.scheduledAt == result.first.scheduledAt)
          .toList();
      final sibs = firstChain.first.siblingIds();
      expect(sibs, hasLength(firstChain.length));
      for (final r in firstChain) {
        expect(sibs, contains(r.id));
      }
    });
  });
}
