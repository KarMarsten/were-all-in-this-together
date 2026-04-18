import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/data/encrypted_medication_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

void main() {
  group('schema v1 backwards compatibility', () {
    test('v1 payload with no schedule field decodes to asNeeded', () {
      // A concrete v1 payload the app might have written before the
      // schedule field existed. This exact JSON shape must decode
      // forever.
      final json = <String, dynamic>{
        'v': 1,
        'name': 'Methylphenidate',
        'dose': '10mg',
        'form': 'pill',
      };

      final payload = EncryptedMedicationPayload.fromJson(json);

      expect(payload.schemaVersion, 1);
      expect(payload.name, 'Methylphenidate');
      expect(payload.schedule, MedicationSchedule.asNeeded);
    });

    test('v2 payload without schedule key still decodes (omitted == default)',
        () {
      final json = <String, dynamic>{
        'v': 2,
        'name': 'Vitamin D',
      };

      final payload = EncryptedMedicationPayload.fromJson(json);

      expect(payload.schemaVersion, 2);
      expect(payload.schedule, MedicationSchedule.asNeeded);
    });
  });

  group('daily schedule round-trip', () {
    test('emits schedule sub-object and round-trips', () {
      const original = EncryptedMedicationPayload(
        schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
        name: 'Omeprazole',
        schedule: MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [
            ScheduledTime(hour: 8, minute: 0),
            ScheduledTime(hour: 20, minute: 30),
          ],
        ),
      );

      final encoded = original.toJson();
      expect(encoded['schedule'], isA<Map<String, dynamic>>());
      final schedule = encoded['schedule'] as Map<String, dynamic>;
      expect(schedule['kind'], 'daily');
      expect(schedule['times'], ['08:00', '20:30']);
      // Daily schedules never carry days — that's a weekly-only field.
      expect(schedule.containsKey('days'), isFalse);

      final decoded = EncryptedMedicationPayload.fromJson(encoded);
      expect(decoded.schedule.kind, ScheduleKind.daily);
      expect(decoded.schedule.times, [
        const ScheduledTime(hour: 8, minute: 0),
        const ScheduledTime(hour: 20, minute: 30),
      ]);
      expect(decoded.schedule.days, isEmpty);
    });

    test('times are sorted and deduped on encode', () {
      // Out-of-order, with a duplicate. Must serialise canonically so
      // two logically-equal schedules produce byte-identical JSON.
      const original = EncryptedMedicationPayload(
        schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
        name: 'Caffeine',
        schedule: MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [
            ScheduledTime(hour: 20, minute: 0),
            ScheduledTime(hour: 8, minute: 0),
            ScheduledTime(hour: 8, minute: 0),
            ScheduledTime(hour: 14, minute: 15),
          ],
        ),
      );

      final schedule =
          original.toJson()['schedule'] as Map<String, dynamic>;
      expect(schedule['times'], ['08:00', '14:15', '20:00']);
    });
  });

  group('weekly schedule round-trip', () {
    test('emits sorted days and round-trips', () {
      const original = EncryptedMedicationPayload(
        schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
        name: 'Methotrexate',
        schedule: MedicationSchedule(
          kind: ScheduleKind.weekly,
          times: [ScheduledTime(hour: 9, minute: 0)],
          days: {5, 1, 3},
        ),
      );

      final schedule =
          original.toJson()['schedule'] as Map<String, dynamic>;
      expect(schedule['kind'], 'weekly');
      expect(schedule['days'], [1, 3, 5]);
      expect(schedule['times'], ['09:00']);

      final decoded =
          EncryptedMedicationPayload.fromJson(original.toJson());
      expect(decoded.schedule.kind, ScheduleKind.weekly);
      expect(decoded.schedule.days, {1, 3, 5});
    });
  });

  group('asNeeded serialisation', () {
    test('omits the schedule key entirely so it looks v1-ish on the wire',
        () {
      const original = EncryptedMedicationPayload(
        schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
        name: 'Acetaminophen',
        schedule: MedicationSchedule.asNeeded,
      );

      // Keeping v2 asNeeded byte-identical to v1 (modulo the `v` bump)
      // means Phase 2 sync diffs won't explode on the migration.
      expect(original.toJson().containsKey('schedule'), isFalse);
    });
  });

  group('tolerant decoding', () {
    test('weekly with empty days falls back to asNeeded', () {
      // Self-contradictory payload: kind says weekly but no days are
      // listed. We choose to keep the row readable rather than throw.
      final json = <String, dynamic>{
        'v': 2,
        'name': 'Broken',
        'schedule': <String, dynamic>{
          'kind': 'weekly',
          'times': <String>['08:00'],
          'days': <int>[],
        },
      };

      final payload = EncryptedMedicationPayload.fromJson(json);
      expect(payload.schedule, MedicationSchedule.asNeeded);
    });

    test('unknown kind string decodes to asNeeded', () {
      final json = <String, dynamic>{
        'v': 2,
        'name': 'Future',
        'schedule': <String, dynamic>{
          'kind': 'monthly-from-a-newer-build',
          'times': <String>['08:00'],
        },
      };

      final payload = EncryptedMedicationPayload.fromJson(json);
      expect(payload.schedule.kind, ScheduleKind.asNeeded);
    });

    test('malformed time strings are skipped rather than failing the row',
        () {
      final json = <String, dynamic>{
        'v': 2,
        'name': 'Partial',
        'schedule': <String, dynamic>{
          'kind': 'daily',
          'times': <String>['08:00', 'not-a-time', '25:61', '20:30'],
        },
      };

      final payload = EncryptedMedicationPayload.fromJson(json);
      expect(payload.schedule.kind, ScheduleKind.daily);
      expect(payload.schedule.times, [
        const ScheduledTime(hour: 8, minute: 0),
        const ScheduledTime(hour: 20, minute: 30),
      ]);
    });
  });

  group('isReminderEligible', () {
    test('true for daily with times', () {
      const s = MedicationSchedule(
        kind: ScheduleKind.daily,
        times: [ScheduledTime(hour: 8, minute: 0)],
      );
      expect(s.isReminderEligible, isTrue);
    });

    test('false for asNeeded', () {
      expect(MedicationSchedule.asNeeded.isReminderEligible, isFalse);
    });

    test('false for weekly with no times (user picked days but no time)', () {
      const s = MedicationSchedule(
        kind: ScheduleKind.weekly,
        days: {1, 3, 5},
      );
      expect(s.isReminderEligible, isFalse);
    });
  });

  test('includes MedicationForm in a full v2 round-trip', () {
    // Sanity check that existing v1 fields still round-trip alongside
    // the new schedule block.
    final original = EncryptedMedicationPayload(
      schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
      name: 'Test',
      dose: '5ml',
      form: MedicationForm.liquid,
      prescriber: 'Dr. Who',
      notes: 'keep refrigerated',
      startDate: DateTime.utc(2031, 3, 14),
      endDate: DateTime.utc(2031, 4),
      schedule: const MedicationSchedule(
        kind: ScheduleKind.daily,
        times: [ScheduledTime(hour: 7, minute: 30)],
      ),
    );

    final decoded =
        EncryptedMedicationPayload.fromJson(original.toJson());

    expect(decoded.name, 'Test');
    expect(decoded.dose, '5ml');
    expect(decoded.form, MedicationForm.liquid);
    expect(decoded.prescriber, 'Dr. Who');
    expect(decoded.notes, 'keep refrigerated');
    expect(decoded.startDate, DateTime.utc(2031, 3, 14));
    expect(decoded.endDate, DateTime.utc(2031, 4));
    expect(decoded.schedule.kind, ScheduleKind.daily);
    expect(decoded.schedule.times.first,
        const ScheduledTime(hour: 7, minute: 30));
  });
}
