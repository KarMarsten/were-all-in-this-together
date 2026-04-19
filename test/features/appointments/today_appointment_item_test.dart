import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/domain/today_appointment_item.dart';

Appointment _appt({
  required String id,
  required DateTime scheduledAt,
  DateTime? deletedAt,
  String title = 'Visit',
}) {
  final created = DateTime.utc(2030);
  return Appointment(
    id: id,
    personId: 'p1',
    title: title,
    scheduledAt: scheduledAt,
    createdAt: created,
    updatedAt: created,
    deletedAt: deletedAt,
  );
}

OwnedTodayAppointment _owned(Appointment appt) =>
    OwnedTodayAppointment(appointment: appt, personDisplayName: 'Alex');

void main() {
  group('expandTodayAppointmentItems', () {
    test('returns only appointments inside [from, to) and sorts ascending',
        () {
      final before = _appt(
        id: 'before',
        scheduledAt: DateTime.utc(2030, 6, 1, 23),
      );
      final inside1 = _appt(
        id: 'inside1',
        scheduledAt: DateTime.utc(2030, 6, 2, 9),
      );
      final inside2 = _appt(
        id: 'inside2',
        scheduledAt: DateTime.utc(2030, 6, 2, 15),
      );
      final atUpperBound = _appt(
        id: 'atUpperBound',
        scheduledAt: DateTime.utc(2030, 6, 3),
      );

      final out = expandTodayAppointmentItems(
        appointments: [before, inside2, atUpperBound, inside1].map(_owned),
        fromInclusive: DateTime.utc(2030, 6, 2),
        toExclusive: DateTime.utc(2030, 6, 3),
      );

      expect(
        out.map((item) => item.appointment.id),
        ['inside1', 'inside2'],
        reason: 'from is inclusive, to is exclusive, sorted by scheduledAt',
      );
    });

    test('drops archived rows defensively', () {
      final archived = _appt(
        id: 'archived',
        scheduledAt: DateTime.utc(2030, 6, 2, 10),
        deletedAt: DateTime.utc(2030, 6, 1, 9),
      );
      final kept = _appt(
        id: 'kept',
        scheduledAt: DateTime.utc(2030, 6, 2, 11),
      );

      final out = expandTodayAppointmentItems(
        appointments: [archived, kept].map(_owned),
        fromInclusive: DateTime.utc(2030, 6, 2),
        toExclusive: DateTime.utc(2030, 6, 3),
      );

      expect(out.map((i) => i.appointment.id), ['kept']);
    });

    test('preserves appointment and display name on the wrapped item', () {
      final appt = _appt(
        id: 'a',
        scheduledAt: DateTime.utc(2030, 6, 2, 10),
        title: 'Dr. Chen',
      );
      final out = expandTodayAppointmentItems(
        appointments: [
          OwnedTodayAppointment(appointment: appt, personDisplayName: 'Sam'),
        ],
        fromInclusive: DateTime.utc(2030, 6, 2),
        toExclusive: DateTime.utc(2030, 6, 3),
      );
      expect(out, hasLength(1));
      expect(out.single.appointment.title, 'Dr. Chen');
      expect(out.single.personDisplayName, 'Sam');
      expect(out.single.personId, 'p1');
      expect(out.single.scheduledAt, DateTime.utc(2030, 6, 2, 10));
    });

    test('accepts local-time from/to by normalising to UTC internally', () {
      // A local-time window covering 2030-06-02 wall-clock should
      // still contain a UTC-noon appointment regardless of host TZ.
      final appt = _appt(
        id: 'a',
        scheduledAt: DateTime.utc(2030, 6, 2, 12),
      );
      final localFrom = DateTime(2030, 6, 2).toLocal();
      final localTo = DateTime(2030, 6, 3).toLocal();

      final out = expandTodayAppointmentItems(
        appointments: [appt].map(_owned),
        fromInclusive: localFrom,
        toExclusive: localTo,
      );

      // Only assert "contained or not" based on host TZ — the helper's
      // contract is "compare by UTC", so this is just proving it doesn't
      // double-convert and mis-classify an appointment clearly inside
      // the UTC window.
      expect(out.map((i) => i.appointment.id), contains('a'));
    });
  });
}
