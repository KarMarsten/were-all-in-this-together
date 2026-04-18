import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/features/medications/data/encrypted_medication_group_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

void main() {
  group('EncryptedMedicationGroupPayload', () {
    test('round-trips v1 with schedule + members', () {
      const payload = EncryptedMedicationGroupPayload(
        schemaVersion: 1,
        name: 'Morning stack',
        schedule: MedicationSchedule(
          kind: ScheduleKind.daily,
          times: [ScheduledTime(hour: 8, minute: 0)],
        ),
        memberMedicationIds: ['a', 'b', 'c'],
      );

      final decoded = EncryptedMedicationGroupPayload.fromJson(
        payload.toJson(),
      );

      expect(decoded.schemaVersion, 1);
      expect(decoded.name, 'Morning stack');
      expect(decoded.schedule.kind, ScheduleKind.daily);
      expect(decoded.schedule.times.single.hour, 8);
      expect(decoded.memberMedicationIds, ['a', 'b', 'c']);
    });

    test('omits schedule field when asNeeded for wire compactness', () {
      const payload = EncryptedMedicationGroupPayload(
        schemaVersion: 1,
        name: 'PRN',
        schedule: MedicationSchedule.asNeeded,
        memberMedicationIds: ['x'],
      );

      final json = payload.toJson();
      expect(json.containsKey('schedule'), isFalse);

      // Round-trip still works and falls back to asNeeded.
      final decoded = EncryptedMedicationGroupPayload.fromJson(json);
      expect(decoded.schedule.kind, ScheduleKind.asNeeded);
      expect(decoded.memberMedicationIds, ['x']);
    });

    test('emits members even when empty so decoders see an explicit list',
        () {
      const payload = EncryptedMedicationGroupPayload(
        schemaVersion: 1,
        name: 'Empty',
        schedule: MedicationSchedule.asNeeded,
        memberMedicationIds: <String>[],
      );

      final json = payload.toJson();
      expect(json['members'], isA<List<dynamic>>());
      expect((json['members']! as List).isEmpty, isTrue);
    });

    test('drops non-string entries in members defensively', () {
      final decoded = EncryptedMedicationGroupPayload.fromJson(
        <String, Object?>{
          'v': 1,
          'name': 'x',
          'members': <Object?>['a', 42, null, 'b'],
        },
      );
      expect(decoded.memberMedicationIds, ['a', 'b']);
    });

    test('rejects a v=0 payload as malformed', () {
      expect(
        () => EncryptedMedicationGroupPayload.fromJson(<String, Object?>{
          'v': 0,
          'name': 'x',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a payload with a version newer than this build', () {
      const tooNew = EncryptedMedicationGroupPayload.currentSchemaVersion + 1;
      expect(
        () => EncryptedMedicationGroupPayload.fromJson(<String, Object?>{
          'v': tooNew,
          'name': 'x',
        }),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects a payload missing "name"', () {
      expect(
        () => EncryptedMedicationGroupPayload.fromJson(<String, Object?>{
          'v': 1,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
