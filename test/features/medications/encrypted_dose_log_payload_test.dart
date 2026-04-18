import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/features/medications/data/encrypted_dose_log_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';

void main() {
  group('EncryptedDoseLogPayload', () {
    test('round-trips through toJson / fromJson', () {
      final payload = EncryptedDoseLogPayload(
        schemaVersion: EncryptedDoseLogPayload.currentSchemaVersion,
        outcome: DoseOutcome.taken,
        loggedAt: DateTime.utc(2026, 4, 18, 8, 15),
        note: 'Took with breakfast',
      );

      final json = jsonDecode(jsonEncode(payload.toJson()))
          as Map<String, dynamic>;
      final decoded = EncryptedDoseLogPayload.fromJson(json);

      expect(decoded.schemaVersion, payload.schemaVersion);
      expect(decoded.outcome, payload.outcome);
      expect(decoded.loggedAt, payload.loggedAt);
      expect(decoded.note, payload.note);
    });

    test('drops whitespace-only notes on decode', () {
      final json = {
        'v': EncryptedDoseLogPayload.currentSchemaVersion,
        'outcome': 'taken',
        'loggedAt': DateTime.utc(2026).toIso8601String(),
        'note': '',
      };
      final decoded = EncryptedDoseLogPayload.fromJson(json);
      expect(decoded.note, isNull);
    });

    test('unknown outcome decodes as taken (forward-compat)', () {
      final json = {
        'v': EncryptedDoseLogPayload.currentSchemaVersion,
        'outcome': 'postponed',
        'loggedAt': DateTime.utc(2026).toIso8601String(),
      };
      final decoded = EncryptedDoseLogPayload.fromJson(json);
      expect(decoded.outcome, DoseOutcome.taken);
    });

    test('rejects missing v field', () {
      expect(
        () => EncryptedDoseLogPayload.fromJson(<String, dynamic>{
          'outcome': 'taken',
          'loggedAt': DateTime.utc(2026).toIso8601String(),
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects v newer than this build', () {
      expect(
        () => EncryptedDoseLogPayload.fromJson(<String, dynamic>{
          'v': EncryptedDoseLogPayload.currentSchemaVersion + 1,
          'outcome': 'taken',
          'loggedAt': DateTime.utc(2026).toIso8601String(),
        }),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects non-UTC loggedAt', () {
      expect(
        () => EncryptedDoseLogPayload.fromJson(<String, dynamic>{
          'v': EncryptedDoseLogPayload.currentSchemaVersion,
          'outcome': 'taken',
          'loggedAt': '2026-01-01T08:00:00',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('omits note key when null', () {
      final json = EncryptedDoseLogPayload(
        schemaVersion: EncryptedDoseLogPayload.currentSchemaVersion,
        outcome: DoseOutcome.skipped,
        loggedAt: DateTime.utc(2026),
      ).toJson();
      expect(json.containsKey('note'), isFalse);
    });
  });

  group('DoseOutcome', () {
    test('wireName round-trips through fromWireName', () {
      for (final v in DoseOutcome.values) {
        expect(DoseOutcome.fromWireName(v.wireName), v);
      }
    });

    test('null / unknown strings default to taken', () {
      expect(DoseOutcome.fromWireName(null), DoseOutcome.taken);
      expect(DoseOutcome.fromWireName('bogus'), DoseOutcome.taken);
    });
  });
}
