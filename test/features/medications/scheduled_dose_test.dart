import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';

Medication _med({
  required String id,
  required String personId,
  required String name,
  String? dose,
  MedicationForm? form,
  MedicationSchedule schedule = MedicationSchedule.asNeeded,
  DateTime? deletedAt,
}) {
  final created = DateTime.utc(2026);
  return Medication(
    id: id,
    personId: personId,
    name: name,
    dose: dose,
    form: form,
    schedule: schedule,
    createdAt: created,
    updatedAt: created,
    deletedAt: deletedAt,
  );
}

void main() {
  // Local day we're testing against: any day works because the
  // expander just uses whatever bounds it's handed.
  final fromLocal = DateTime(2026, 4, 18);
  final toLocal = fromLocal.add(const Duration(days: 1));

  group('expandDoses', () {
    test('asNeeded meds produce nothing', () {
      final doses = expandDoses(
        medications: [
          DoseSchedulingContext(
            medication: _med(id: 'm1', personId: 'p1', name: 'A'),
            personDisplayName: 'Alex',
          ),
        ],
        fromInclusive: fromLocal.toUtc(),
        toExclusive: toLocal.toUtc(),
      );
      expect(doses, isEmpty);
    });

    test('archived meds produce nothing', () {
      final doses = expandDoses(
        medications: [
          DoseSchedulingContext(
            medication: _med(
              id: 'm1',
              personId: 'p1',
              name: 'A',
              schedule: const MedicationSchedule(
                kind: ScheduleKind.daily,
                times: [ScheduledTime(hour: 8, minute: 0)],
              ),
              deletedAt: DateTime.utc(2026, 4, 17),
            ),
            personDisplayName: 'Alex',
          ),
        ],
        fromInclusive: fromLocal.toUtc(),
        toExclusive: toLocal.toUtc(),
      );
      expect(doses, isEmpty);
    });

    test('daily schedule produces one dose per time in the day', () {
      final doses = expandDoses(
        medications: [
          DoseSchedulingContext(
            medication: _med(
              id: 'm1',
              personId: 'p1',
              name: 'A',
              schedule: const MedicationSchedule(
                kind: ScheduleKind.daily,
                times: [
                  ScheduledTime(hour: 8, minute: 0),
                  ScheduledTime(hour: 20, minute: 30),
                ],
              ),
            ),
            personDisplayName: 'Alex',
          ),
        ],
        fromInclusive: fromLocal,
        toExclusive: toLocal,
      );
      expect(doses, hasLength(2));
      // Sorted ascending.
      expect(doses[0].scheduledAt.isBefore(doses[1].scheduledAt), isTrue);
      // Identity is consistent across both doses.
      for (final d in doses) {
        expect(d.medicationId, 'm1');
        expect(d.personId, 'p1');
        expect(d.personDisplayName, 'Alex');
      }
    });

    test('weekly schedule only fires on selected ISO weekdays', () {
      // 2026-04-18 is a Saturday (ISO 6). We pass a 7-day window so we
      // can verify only the selected days fire.
      final from = DateTime(2026, 4, 18);
      final to = from.add(const Duration(days: 7));
      final doses = expandDoses(
        medications: [
          DoseSchedulingContext(
            medication: _med(
              id: 'm1',
              personId: 'p1',
              name: 'A',
              schedule: const MedicationSchedule(
                kind: ScheduleKind.weekly,
                days: {1, 3}, // Mon, Wed
                times: [ScheduledTime(hour: 9, minute: 0)],
              ),
            ),
            personDisplayName: 'Alex',
          ),
        ],
        fromInclusive: from,
        toExclusive: to,
      );
      expect(doses, hasLength(2));
      for (final d in doses) {
        final weekday = d.scheduledAt.toLocal().weekday;
        expect(weekday == 1 || weekday == 3, isTrue);
      }
    });

    test('reminder-ineligible (daily, no times) produces nothing', () {
      final doses = expandDoses(
        medications: [
          DoseSchedulingContext(
            medication: _med(
              id: 'm1',
              personId: 'p1',
              name: 'A',
              schedule: const MedicationSchedule(kind: ScheduleKind.daily),
            ),
            personDisplayName: 'Alex',
          ),
        ],
        fromInclusive: fromLocal,
        toExclusive: toLocal,
      );
      expect(doses, isEmpty);
    });

    test('equality identity is (medicationId, scheduledAt)', () {
      final d1 = ScheduledDose(
        medicationId: 'm1',
        personId: 'p1',
        medicationName: 'A',
        personDisplayName: 'Alex',
        scheduledAt: DateTime.utc(2026, 4, 18, 8),
      );
      final d2 = ScheduledDose(
        medicationId: 'm1',
        personId: 'p1',
        medicationName: 'Different name',
        personDisplayName: 'Different person',
        scheduledAt: DateTime.utc(2026, 4, 18, 8),
        dose: '10mg',
      );
      expect(d1, equals(d2));
      expect(d1.hashCode, d2.hashCode);
    });
  });
}
