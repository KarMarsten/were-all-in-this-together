import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/data/encrypted_medication_event_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';

/// `EncryptedMedicationEventPayload` is a forever-compatible wire
/// format. Every schema version the app has ever emitted must
/// round-trip through `fromJson` / `toJson` into equivalent values.
/// These tests are the spec for that contract.
void main() {
  group('v1 round-trip', () {
    test('created event emits no diffs and no note', () {
      const p = EncryptedMedicationEventPayload(
        schemaVersion: 1,
        kind: MedicationEventKind.created,
      );

      final roundTripped = EncryptedMedicationEventPayload.fromJson(p.toJson());

      expect(roundTripped.schemaVersion, 1);
      expect(roundTripped.kind, MedicationEventKind.created);
      expect(roundTripped.diffs, isEmpty);
      expect(roundTripped.note, isNull);
    });

    test('fieldsChanged carries diffs with optional prev/curr', () {
      const p = EncryptedMedicationEventPayload(
        schemaVersion: 1,
        kind: MedicationEventKind.fieldsChanged,
        diffs: [
          MedicationFieldDiff(field: 'dose', previous: '10mg', current: '20mg'),
          MedicationFieldDiff(field: 'prescriberId', current: 'p-123'),
          MedicationFieldDiff(field: 'endDate', previous: '2026-01-01'),
        ],
      );

      final roundTripped = EncryptedMedicationEventPayload.fromJson(p.toJson());

      expect(roundTripped.diffs, hasLength(3));
      expect(roundTripped.diffs[0].field, 'dose');
      expect(roundTripped.diffs[0].previous, '10mg');
      expect(roundTripped.diffs[0].current, '20mg');
      expect(roundTripped.diffs[1].previous, isNull);
      expect(roundTripped.diffs[1].current, 'p-123');
      expect(roundTripped.diffs[2].previous, '2026-01-01');
      expect(roundTripped.diffs[2].current, isNull);
    });

    test('note kind preserves the free-text body', () {
      const p = EncryptedMedicationEventPayload(
        schemaVersion: 1,
        kind: MedicationEventKind.note,
        note: 'Started feeling nauseous — told Dr. Chen.',
      );

      final roundTripped = EncryptedMedicationEventPayload.fromJson(p.toJson());

      expect(roundTripped.kind, MedicationEventKind.note);
      expect(roundTripped.note, 'Started feeling nauseous — told Dr. Chen.');
    });
  });

  group('tolerant decode', () {
    // Matches `MedicationEventKind.fromWireName`'s fallback — an
    // unknown kind from a newer build should *still* render rather
    // than hide history. We pick `note` as the fallback because its
    // contract is "free text the user added to the timeline", which
    // won't mislead.
    test('unknown kind decodes to note', () {
      final p = EncryptedMedicationEventPayload.fromJson(<String, dynamic>{
        'v': 1,
        'kind': 'someFutureKind',
      });
      expect(p.kind, MedicationEventKind.note);
    });

    test('malformed diff entries are dropped, not fatal', () {
      final p = EncryptedMedicationEventPayload.fromJson(<String, dynamic>{
        'v': 1,
        'kind': 'fieldsChanged',
        'diffs': [
          'not-a-map',
          {'field': 'dose', 'current': '5mg'},
          // Missing `field` — must be skipped.
          {'current': 'oops'},
        ],
      });
      expect(p.diffs, hasLength(1));
      expect(p.diffs.single.field, 'dose');
    });
  });

  group('error cases', () {
    test('missing v throws FormatException', () {
      expect(
        () => EncryptedMedicationEventPayload.fromJson(<String, dynamic>{
          'kind': 'created',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('v newer than build throws UnsupportedError', () {
      expect(
        () => EncryptedMedicationEventPayload.fromJson(<String, dynamic>{
          'v': EncryptedMedicationEventPayload.currentSchemaVersion + 1,
          'kind': 'created',
        }),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('invalid v < 1 throws FormatException', () {
      expect(
        () => EncryptedMedicationEventPayload.fromJson(<String, dynamic>{
          'v': 0,
          'kind': 'created',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing kind throws FormatException', () {
      expect(
        () => EncryptedMedicationEventPayload.fromJson(<String, dynamic>{
          'v': 1,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('byte-size discipline', () {
    // Empty fields must be omitted rather than serialised as nulls
    // so historical payloads stay compact and new fields don't pay
    // a bytes tax on every row that doesn't use them.
    test('null note and empty diffs are omitted from JSON', () {
      const p = EncryptedMedicationEventPayload(
        schemaVersion: 1,
        kind: MedicationEventKind.archived,
      );
      final json = p.toJson();
      expect(json.containsKey('note'), isFalse);
      expect(json.containsKey('diffs'), isFalse);
    });

    test('null previous / current are omitted per diff entry', () {
      const p = EncryptedMedicationEventPayload(
        schemaVersion: 1,
        kind: MedicationEventKind.fieldsChanged,
        diffs: [MedicationFieldDiff(field: 'dose', current: '5mg')],
      );
      final json = p.toJson();
      final diffs = json['diffs']! as List<dynamic>;
      final entry = diffs.single as Map<String, dynamic>;
      expect(entry.containsKey('previous'), isFalse);
      expect(entry['current'], '5mg');
    });
  });
}
