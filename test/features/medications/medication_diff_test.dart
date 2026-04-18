import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_diff.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// `diffMedicationFields` defines which changes are considered
/// medically-meaningful enough to log on the timeline. These tests
/// pin that contract — adding a field to the diff set (or dropping
/// one) should update both the helper and these tests together.
void main() {
  final t = DateTime.utc(2030);
  Medication base() => Medication(
        id: 'm1',
        personId: 'alex',
        name: 'Concerta',
        createdAt: t,
        updatedAt: t,
        dose: '10mg',
        form: MedicationForm.pill,
        prescriber: 'Dr. Chen',
        prescriberId: 'p-1',
        schedule: const MedicationSchedule(kind: ScheduleKind.daily),
        startDate: DateTime.utc(2025, 3),
      );

  group('tracks medically-meaningful fields', () {
    test('dose change produces a single dose diff', () {
      final before = base();
      final after = before.copyWith(dose: '20mg');

      final diffs = diffMedicationFields(before: before, after: after);

      expect(diffs, hasLength(1));
      expect(diffs.single.field, 'dose');
      expect(diffs.single.previous, '10mg');
      expect(diffs.single.current, '20mg');
    });

    test('prescriber link change produces a prescriberId diff', () {
      final before = base();
      final after = before.copyWith(prescriberId: 'p-2');

      final diffs = diffMedicationFields(before: before, after: after);

      expect(diffs.map((d) => d.field), ['prescriberId']);
      expect(diffs.single.previous, 'p-1');
      expect(diffs.single.current, 'p-2');
    });

    test('clearing a field produces prev-only diff', () {
      final before = base();
      final after = before.copyWith(prescriberId: null);

      final diffs = diffMedicationFields(before: before, after: after);

      expect(diffs.single.field, 'prescriberId');
      expect(diffs.single.previous, 'p-1');
      expect(diffs.single.current, isNull);
    });

    test('schedule kind change is stringified in a stable wire form', () {
      final before = base().copyWith(
        schedule: MedicationSchedule.asNeeded,
      );
      final after = before.copyWith(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.weekly,
          days: {1, 3, 5},
          times: [ScheduledTime(hour: 9, minute: 0)],
        ),
      );

      final diffs = diffMedicationFields(before: before, after: after);

      expect(diffs.single.field, 'schedule');
      expect(diffs.single.previous, 'asNeeded');
      expect(diffs.single.current, 'weekly[1,3,5]@09:00');
    });

    test('start date change renders as YYYY-MM-DD', () {
      final before = base();
      final after = before.copyWith(startDate: DateTime.utc(2026, 4, 18));

      final diffs = diffMedicationFields(before: before, after: after);

      expect(diffs.single.field, 'startDate');
      expect(diffs.single.previous, '2025-03-01');
      expect(diffs.single.current, '2026-04-18');
    });

    test('form change uses the wire name (not the localized label)', () {
      final before = base();
      final after = before.copyWith(form: MedicationForm.liquid);

      final diffs = diffMedicationFields(before: before, after: after);

      expect(diffs.single.field, 'form');
      expect(diffs.single.previous, MedicationForm.pill.wireName);
      expect(diffs.single.current, MedicationForm.liquid.wireName);
    });
  });

  group('ignores behavioural / casual fields', () {
    // Notes change casually — "felt tired today" — and would
    // crowd the regimen timeline. Reminder overrides are
    // behavioral, not medical. Neither belongs in history.
    test('notes change produces no diff', () {
      final before = base().copyWith(notes: 'take with food');
      final after = before.copyWith(notes: 'take with food and water');

      expect(diffMedicationFields(before: before, after: after), isEmpty);
    });

    test('reminder override changes produce no diff', () {
      final before = base();
      final after = before.copyWith(
        nagIntervalMinutesOverride: 15,
        nagCapOverride: 4,
      );

      expect(diffMedicationFields(before: before, after: after), isEmpty);
    });
  });

  group('null `before` (first-time set)', () {
    test('produces "current set" diffs for every populated field', () {
      final after = base();

      final diffs = diffMedicationFields(before: null, after: after);

      final fields = {for (final d in diffs) d.field};
      expect(fields, containsAll([
        'name',
        'dose',
        'form',
        'prescriber',
        'prescriberId',
        'schedule',
        'startDate',
      ]));
      for (final d in diffs) {
        expect(d.previous, isNull, reason: 'set-from-nothing has no previous');
        expect(d.current, isNotNull);
      }
    });
  });

  group('whitespace-only equals blank', () {
    // Trimming keeps "" and "   " on equal footing — otherwise a
    // save that accidentally typed a space into the prescriber note
    // would fill the timeline with a meaningless diff.
    test('setting prescriber from null to "" produces no diff', () {
      final before = base().copyWith(prescriber: null);
      final after = before.copyWith(prescriber: '   ');

      expect(diffMedicationFields(before: before, after: after), isEmpty);
    });
  });
}
