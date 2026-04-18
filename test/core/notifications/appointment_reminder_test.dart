import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/notifications/appointment_reminder.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';

void main() {
  group('AppointmentReminder', () {
    test('id derives from appointmentId alone (stable across edits)', () {
      final scheduled = DateTime.utc(2030, 1, 7, 15);
      final a = AppointmentReminder(
        appointmentId: 'appt-abc',
        personId: 'p1',
        personDisplayName: 'Alex',
        title: 'Dr. Chen — flu shot',
        scheduledAt: scheduled,
        fireAt: scheduled.subtract(const Duration(minutes: 30)),
        leadMinutes: 30,
      );
      final b = AppointmentReminder(
        appointmentId: 'appt-abc',
        personId: 'p1',
        personDisplayName: 'Alex',
        // Title and fireAt changed; id must stay the same so the
        // OS overwrite path kicks in.
        title: 'Dr. Chen — rescheduled',
        scheduledAt: scheduled.add(const Duration(hours: 2)),
        fireAt: scheduled.add(const Duration(hours: 2, minutes: -15)),
        leadMinutes: 15,
      );
      expect(a.id, b.id);
    });

    test('id differs for different appointments', () {
      final scheduled = DateTime.utc(2030, 1, 7, 15);
      final a = AppointmentReminder(
        appointmentId: 'appt-abc',
        personId: 'p1',
        personDisplayName: 'Alex',
        title: 'x',
        scheduledAt: scheduled,
        fireAt: scheduled.subtract(const Duration(minutes: 30)),
      );
      final b = AppointmentReminder(
        appointmentId: 'appt-xyz',
        personId: 'p1',
        personDisplayName: 'Alex',
        title: 'x',
        scheduledAt: scheduled,
        fireAt: scheduled.subtract(const Duration(minutes: 30)),
      );
      expect(a.id, isNot(b.id));
    });

    test('id is always non-negative (fits signed 31 bits)', () {
      for (var i = 0; i < 200; i++) {
        final reminder = AppointmentReminder(
          appointmentId: 'appt-$i',
          personId: 'p',
          personDisplayName: 'A',
          title: 't',
          scheduledAt: DateTime.utc(2030, 1, 7, 15),
          fireAt: DateTime.utc(2030, 1, 7, 14),
        );
        expect(reminder.id, greaterThanOrEqualTo(0));
        expect(reminder.id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('UTC assertion fires on local DateTime inputs', () {
      expect(
        () => AppointmentReminder(
          appointmentId: 'a',
          personId: 'p',
          personDisplayName: 'A',
          title: 't',
          scheduledAt: DateTime(2030, 1, 7, 15),
          fireAt: DateTime.utc(2030, 1, 7, 14),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('displayTitle prepends Person name', () {
      final reminder = _reminder(
        personDisplayName: 'Sam',
        title: 'Flu shot',
      );
      expect(reminder.displayTitle, 'Sam · Flu shot');
    });

    test('body formats minutes under an hour as "In N min"', () {
      expect(_reminder().body, 'In 30 min');
    });

    test('body formats 60 minutes as "In 1 hour"', () {
      expect(_reminder(leadMinutes: 60).body, 'In 1 hour');
    });

    test('body formats whole multi-hour leads as "In N hours"', () {
      expect(_reminder(leadMinutes: 180).body, 'In 3 hours');
    });

    test('body formats 1440 minutes as "Tomorrow"', () {
      expect(_reminder(leadMinutes: 1440).body, 'Tomorrow');
    });

    test('body appends trimmed location when present', () {
      final r = _reminder(location: '  Clinic A  ');
      expect(r.body, 'In 30 min · Clinic A');
    });

    test('body falls back to generic copy when lead and location absent', () {
      final r = _reminder(leadMinutes: null, location: '');
      expect(r.body, 'Upcoming appointment');
    });

    test('body copes with non-positive lead values', () {
      final r = _reminder(leadMinutes: 0, location: 'Clinic');
      expect(r.body, 'Starting now · Clinic');
    });

    test('encodePayload round-trips through tryDecode', () {
      final scheduled = DateTime.utc(2030, 1, 7, 15);
      final reminder = AppointmentReminder(
        appointmentId: 'appt-abc',
        personId: 'p1',
        personDisplayName: 'Alex',
        title: 'Dr. Chen',
        scheduledAt: scheduled,
        fireAt: scheduled.subtract(const Duration(minutes: 30)),
      );
      final decoded = AppointmentReminderPayload.tryDecode(
        reminder.encodePayload(),
      );
      expect(decoded, isNotNull);
      expect(decoded!.appointmentId, 'appt-abc');
      expect(decoded.personId, 'p1');
      expect(decoded.scheduledAtUtcMs, scheduled.millisecondsSinceEpoch);
      expect(decoded.scheduledAt, scheduled);
    });

    test('encoded payload carries kind=appt on the wire', () {
      final reminder = _reminder();
      final map = jsonDecode(reminder.encodePayload()) as Map;
      expect(map['kind'], ReminderPayloadKind.appointment);
    });

    test('AppointmentReminderPayload.tryDecode rejects med payloads', () {
      final medPayload = ScheduledReminder(
        medicationId: 'm',
        personId: 'p',
        medicationName: 'Zinc',
        personDisplayName: 'A',
        scheduledAt: DateTime.utc(2030, 1, 7, 15),
        fireAt: DateTime.utc(2030, 1, 7, 15),
        nagIndex: 0,
        totalInChain: 1,
      ).encodePayload();
      expect(AppointmentReminderPayload.tryDecode(medPayload), isNull);
    });

    test('AppointmentReminderPayload.tryDecode returns null on garbage', () {
      expect(AppointmentReminderPayload.tryDecode(null), isNull);
      expect(AppointmentReminderPayload.tryDecode(''), isNull);
      expect(AppointmentReminderPayload.tryDecode('not json'), isNull);
      expect(AppointmentReminderPayload.tryDecode('"a string"'), isNull);
    });
  });

  group('peekReminderPayloadKind', () {
    test('returns "med" for legacy payloads without a kind field', () {
      final legacy = jsonEncode(<String, Object?>{
        'v': 1,
        'mid': 'm',
        'pid': 'p',
        'tsUtc': 0,
        'nag': 0,
        'total': 1,
        'siblings': <int>[],
      });
      expect(peekReminderPayloadKind(legacy), ReminderPayloadKind.medication);
    });

    test('returns the explicit kind when present', () {
      final payload = _reminder().encodePayload();
      expect(
        peekReminderPayloadKind(payload),
        ReminderPayloadKind.appointment,
      );
    });

    test('returns null for unparseable input', () {
      expect(peekReminderPayloadKind(null), isNull);
      expect(peekReminderPayloadKind(''), isNull);
      expect(peekReminderPayloadKind('{'), isNull);
      expect(peekReminderPayloadKind('42'), isNull);
    });
  });

  group('ReminderPayload legacy compatibility', () {
    test('decodes legacy payloads with no kind field as medication', () {
      final legacy = jsonEncode(<String, Object?>{
        'v': 1,
        'mid': 'med-1',
        'pid': 'p-1',
        'tsUtc': 1700000000000,
        'nag': 0,
        'total': 1,
        'siblings': <int>[],
      });
      final decoded = ReminderPayload.tryDecode(legacy);
      expect(decoded, isNotNull);
      expect(decoded!.medicationId, 'med-1');
    });

    test('rejects appointment payloads so the ACK handler ignores them', () {
      final apptPayload = _reminder().encodePayload();
      expect(ReminderPayload.tryDecode(apptPayload), isNull);
    });
  });
}

AppointmentReminder _reminder({
  String personDisplayName = 'Alex',
  String title = 'Visit',
  int? leadMinutes = 30,
  String? location,
}) {
  final scheduled = DateTime.utc(2030, 1, 7, 15);
  return AppointmentReminder(
    appointmentId: 'appt-1',
    personId: 'p1',
    personDisplayName: personDisplayName,
    title: title,
    scheduledAt: scheduled,
    fireAt: scheduled.subtract(Duration(minutes: leadMinutes ?? 0)),
    leadMinutes: leadMinutes,
    location: location,
  );
}
