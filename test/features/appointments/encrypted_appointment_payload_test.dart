import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/features/appointments/data/encrypted_appointment_payload.dart';

/// Wire-format tests for `EncryptedAppointmentPayload`.
///
/// The schema is forever-compatible — every historical `v` the app
/// has ever emitted must still decode. Tests here lock in the v1
/// contract and the error surface (missing required fields,
/// version too new, forward-compat on unknown keys).
void main() {
  group('v1 round-trip', () {
    test('full payload round-trips via toJson / fromJson', () {
      const original = EncryptedAppointmentPayload(
        schemaVersion: 1,
        title: 'Dr. Chen — flu shot',
        providerId: 'prov-123',
        location: "Dr. Chen's office",
        durationMinutes: 30,
        notes: 'Bring insurance card',
        reminderLeadMinutes: 60,
      );

      final decoded = EncryptedAppointmentPayload.fromJson(original.toJson());

      expect(decoded.schemaVersion, 1);
      expect(decoded.title, 'Dr. Chen — flu shot');
      expect(decoded.providerId, 'prov-123');
      expect(decoded.location, "Dr. Chen's office");
      expect(decoded.durationMinutes, 30);
      expect(decoded.notes, 'Bring insurance card');
      expect(decoded.reminderLeadMinutes, 60);
    });

    test('minimal payload (title only) round-trips', () {
      const original = EncryptedAppointmentPayload(
        schemaVersion: 1,
        title: 'School meeting',
      );

      final json = original.toJson();
      // Byte-size discipline: null / omitted fields should not
      // appear in the JSON at all. The encrypted blob is the
      // hottest column on the row, and carrying nulls for every
      // optional field would bloat it with no signal.
      expect(json.keys, unorderedEquals(<String>['v', 'title']));

      final decoded = EncryptedAppointmentPayload.fromJson(json);
      expect(decoded.title, 'School meeting');
      expect(decoded.providerId, isNull);
      expect(decoded.location, isNull);
      expect(decoded.durationMinutes, isNull);
      expect(decoded.notes, isNull);
      expect(decoded.reminderLeadMinutes, isNull);
    });
  });

  group('fromJson errors', () {
    test('missing "v" throws FormatException', () {
      expect(
        () => EncryptedAppointmentPayload.fromJson({'title': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('negative or zero "v" throws FormatException', () {
      expect(
        () => EncryptedAppointmentPayload.fromJson({'v': 0, 'title': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('future "v" throws UnsupportedError', () {
      expect(
        () => EncryptedAppointmentPayload.fromJson({'v': 999, 'title': 'x'}),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('missing "title" throws FormatException', () {
      expect(
        () => EncryptedAppointmentPayload.fromJson({'v': 1}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('forward-compat', () {
    test('unknown keys in a v1 payload are ignored', () {
      // A future build may add fields we don't know about; older
      // builds must decode what they can and silently drop the
      // rest, never throw.
      final decoded = EncryptedAppointmentPayload.fromJson({
        'v': 1,
        'title': 'Checkup',
        'futureField': 'whatever',
        'anotherFuture': 42,
      });
      expect(decoded.title, 'Checkup');
    });

    test('JSON-decoded numeric field arrives as double', () {
      // `jsonDecode` returns `int` when the source is integral but
      // tests with manually-built maps occasionally pass `double`s;
      // `_readInt` must coerce both.
      final decoded = EncryptedAppointmentPayload.fromJson({
        'v': 1,
        'title': 'Checkup',
        'durationMinutes': 30.0,
      });
      expect(decoded.durationMinutes, 30);
    });
  });
}
