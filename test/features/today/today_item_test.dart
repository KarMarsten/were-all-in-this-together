import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';
import 'package:were_all_in_this_together/features/today/domain/today_item.dart';

Medication _med({
  String id = 'm1',
  String personId = 'alex',
  String name = 'Aspirin',
  MedicationSchedule schedule = MedicationSchedule.asNeeded,
}) {
  final now = DateTime.utc(2026);
  return Medication(
    id: id,
    personId: personId,
    name: name,
    schedule: schedule,
    createdAt: now,
    updatedAt: now,
  );
}

MedicationGroup _group({
  String id = 'g1',
  String personId = 'alex',
  String name = 'Morning',
  MedicationSchedule schedule = MedicationSchedule.asNeeded,
  List<String> members = const <String>[],
}) {
  final now = DateTime.utc(2026);
  return MedicationGroup(
    id: id,
    personId: personId,
    name: name,
    schedule: schedule,
    memberMedicationIds: members,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // Use local-midnight boundaries — expandTodayItems expects the
  // caller to clip to the rendered day.
  final today = DateTime(2026, 4, 18);
  final tomorrow = today.add(const Duration(days: 1));

  group('expandTodayItems', () {
    test('empty inputs produce an empty list', () {
      final items = expandTodayItems(
        medications: const <DoseSchedulingContext>[],
        groups: const <GroupSchedulingContext>[],
        fromInclusive: today,
        toExclusive: tomorrow,
      );
      expect(items, isEmpty);
    });

    test('a solo med with no group produces TodaySoloItems only', () {
      final med = _med(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );
      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: med, personDisplayName: 'Alex'),
        ],
        groups: const <GroupSchedulingContext>[],
        fromInclusive: today,
        toExclusive: tomorrow,
      );
      expect(items, hasLength(1));
      expect(items.single, isA<TodaySoloItem>());
    });

    test('a group at the same time hides its member solo doses', () {
      final med = _med(
        id: 'aspirin',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
      );
      final group = _group(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin'],
      );

      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: med, personDisplayName: 'Alex'),
        ],
        groups: [
          GroupSchedulingContext(group: group, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );

      // One group item, zero solo items — the solo is covered.
      expect(items, hasLength(1));
      expect(items.single, isA<TodayGroupItem>());
    });

    test('a solo dose at a different time than its group is NOT hidden', () {
      final med = _med(
        id: 'aspirin',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [
            ScheduledTime(hour: 8, minute: 0),
            ScheduledTime(hour: 20, minute: 0),
          ],
        ),
      );
      final group = _group(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin'],
      );

      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: med, personDisplayName: 'Alex'),
        ],
        groups: [
          GroupSchedulingContext(group: group, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );

      // Group at 08:00 covers the 08:00 solo. The 20:00 solo stays.
      expect(items, hasLength(2));
      expect(items.first, isA<TodayGroupItem>()); // 08:00 group
      expect(items.last, isA<TodaySoloItem>()); // 20:00 solo
    });

    test('same med in two groups at same time produces TWO group rows', () {
      // Both groups include aspirin at 08:00. We keep both rows so the
      // user can see both bundles; the repo-level upsert on
      // (medicationId, scheduledAt) guarantees one DoseLog regardless.
      final med = _med(id: 'aspirin');
      final morning = _group(
        id: 'morning',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin'],
      );
      final focus = _group(
        id: 'focus',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin'],
      );

      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: med, personDisplayName: 'Alex'),
        ],
        groups: [
          GroupSchedulingContext(group: morning, personDisplayName: 'Alex'),
          GroupSchedulingContext(group: focus, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );

      expect(items.whereType<TodayGroupItem>(), hasLength(2));
      expect(items.whereType<TodaySoloItem>(), isEmpty);
    });

    test('archived med is dropped from groups', () {
      final archived = _med(
        id: 'aspirin',
      ).copyWith(deletedAt: DateTime.utc(2026));
      final group = _group(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin'],
      );
      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(
            medication: archived,
            personDisplayName: 'Alex',
          ),
        ],
        groups: [
          GroupSchedulingContext(group: group, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );
      expect(items, isEmpty);
    });

    test('asNeeded groups contribute no items', () {
      final group = _group(members: ['aspirin']);
      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: _med(id: 'aspirin'),
              personDisplayName: 'Alex'),
        ],
        groups: [
          GroupSchedulingContext(group: group, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );
      expect(items, isEmpty);
    });

    test('items are sorted by scheduledAt ascending', () {
      final med = _med(
        id: 'aspirin',
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [
            ScheduledTime(hour: 20, minute: 0),
          ],
        ),
      );
      final group = _group(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin'],
      );

      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: med, personDisplayName: 'Alex'),
        ],
        groups: [
          GroupSchedulingContext(group: group, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );

      expect(
        items.map((i) => i.scheduledAt.toLocal().hour).toList(),
        [8, 20],
      );
    });

    test('cross-Person group members are dropped silently', () {
      final alexMed = _med(id: 'aspirin');
      final kitMed = _med(id: 'kit-med', personId: 'kit');
      final group = _group(
        schedule: const MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        members: ['aspirin', 'kit-med'],
      );
      final items = expandTodayItems(
        medications: [
          DoseSchedulingContext(medication: alexMed, personDisplayName: 'Alex'),
          DoseSchedulingContext(medication: kitMed, personDisplayName: 'Kit'),
        ],
        groups: [
          GroupSchedulingContext(group: group, personDisplayName: 'Alex'),
        ],
        fromInclusive: today,
        toExclusive: tomorrow,
      );
      expect(items, hasLength(1));
      expect(items.single, isA<TodayGroupItem>());
      expect(
        (items.single as TodayGroupItem).members.map((d) => d.medicationId),
        ['aspirin'],
      );
    });
  });
}
