import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';

import '../../helpers/in_memory_key_storage.dart';

/// Integration-ish tests for `AppointmentRepository` against a real
/// in-memory Drift DB and real crypto. Pinned clock keeps timestamp
/// assertions deterministic without sleep().
void main() {
  late AppDatabase db;
  late CryptoService crypto;
  late InMemoryKeyStorage keys;
  late PersonRepository people;
  late AppointmentRepository appointments;
  late String alexId;

  // Ticking UTC clock — one ms per call. Used for createdAt /
  // updatedAt / deletedAt; `scheduledAt` is always caller-supplied
  // and unrelated.
  late int clockCallCount;
  DateTime tickingClock() {
    clockCallCount++;
    return DateTime.utc(2030).add(Duration(milliseconds: clockCallCount));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
    clockCallCount = 0;
    people = PersonRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    appointments = AppointmentRepository(
      database: db,
      crypto: crypto,
      keys: keys,
      clock: tickingClock,
    );
    final alex = await people.create(displayName: 'Alex');
    alexId = alex.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('create', () {
    test('returns an Appointment with every provided field', () async {
      final appt = await appointments.create(
        personId: alexId,
        title: 'Dr. Chen — flu shot',
        scheduledAt: DateTime.utc(2030, 6, 1, 14, 30),
        providerId: 'prov-123',
        location: "Dr. Chen's office",
        durationMinutes: 30,
        notes: 'Bring insurance card',
        reminderLeadMinutes: 60,
      );

      expect(appt.id, isNotEmpty);
      expect(appt.personId, alexId);
      expect(appt.title, 'Dr. Chen — flu shot');
      expect(appt.scheduledAt, DateTime.utc(2030, 6, 1, 14, 30));
      expect(appt.providerId, 'prov-123');
      expect(appt.location, "Dr. Chen's office");
      expect(appt.durationMinutes, 30);
      expect(appt.notes, 'Bring insurance card');
      expect(appt.reminderLeadMinutes, 60);
      expect(appt.deletedAt, isNull);
      expect(appt.rowVersion, 1);
    });

    test('rejects a blank title', () async {
      expect(
        () => appointments.create(
          personId: alexId,
          title: '   ',
          scheduledAt: DateTime.utc(2030),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a non-positive duration', () async {
      expect(
        () => appointments.create(
          personId: alexId,
          title: 'x',
          scheduledAt: DateTime.utc(2030),
          durationMinutes: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a negative reminder lead', () async {
      expect(
        () => appointments.create(
          personId: alexId,
          title: 'x',
          scheduledAt: DateTime.utc(2030),
          reminderLeadMinutes: -5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws if the owning Person has no key on this device', () async {
      expect(
        () => appointments.create(
          personId: 'no-such-person',
          title: 'orphaned',
          scheduledAt: DateTime.utc(2030),
        ),
        throwsA(isA<AppointmentKeyMissingError>()),
      );
    });

    test('round-trips through findById including decryption', () async {
      final created = await appointments.create(
        personId: alexId,
        title: 'Round-trip',
        scheduledAt: DateTime.utc(2030, 7, 15, 9),
        notes: 'secret notes',
      );

      final reloaded = await appointments.findById(created.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.title, 'Round-trip');
      expect(reloaded.notes, 'secret notes');
      expect(reloaded.scheduledAt, DateTime.utc(2030, 7, 15, 9));
    });
  });

  group('listUpcoming / listPast', () {
    test('splits at `now`, sorts upcoming ascending and past descending',
        () async {
      final past1 = await appointments.create(
        personId: alexId,
        title: 'Past 1',
        scheduledAt: DateTime.utc(2030, 3, 1, 10),
      );
      final past2 = await appointments.create(
        personId: alexId,
        title: 'Past 2',
        scheduledAt: DateTime.utc(2030, 4, 1, 10),
      );
      final future1 = await appointments.create(
        personId: alexId,
        title: 'Future 1',
        scheduledAt: DateTime.utc(2030, 6, 1, 10),
      );
      final future2 = await appointments.create(
        personId: alexId,
        title: 'Future 2',
        scheduledAt: DateTime.utc(2030, 7, 1, 10),
      );

      final cutoff = DateTime.utc(2030, 5);
      final upcoming =
          await appointments.listUpcomingForPerson(alexId, now: cutoff);
      final pastVisits =
          await appointments.listPastForPerson(alexId, now: cutoff);

      expect(
        upcoming.map((a) => a.id).toList(),
        [future1.id, future2.id],
      );
      expect(
        pastVisits.map((a) => a.id).toList(),
        [past2.id, past1.id],
      );
    });

    test('scopes by personId and excludes archived rows', () async {
      final otherPerson = await people.create(displayName: 'Sibling');
      await appointments.create(
        personId: otherPerson.id,
        title: "Sibling's visit",
        scheduledAt: DateTime.utc(2030, 6),
      );
      final mine = await appointments.create(
        personId: alexId,
        title: 'Mine',
        scheduledAt: DateTime.utc(2030, 6),
      );
      final toArchive = await appointments.create(
        personId: alexId,
        title: 'Cancelled',
        scheduledAt: DateTime.utc(2030, 6, 2),
      );
      await appointments.archive(toArchive.id);

      final upcoming = await appointments.listUpcomingForPerson(
        alexId,
        now: DateTime.utc(2030, 5),
      );
      expect(upcoming.map((a) => a.id), [mine.id]);
    });

    test('an appointment exactly at `now` sorts as upcoming, not past',
        () async {
      // `isBiggerOrEqualValue` is what puts it on the upcoming
      // side; lock that boundary so a refactor can't flip it
      // silently.
      final exactly = await appointments.create(
        personId: alexId,
        title: 'Right now',
        scheduledAt: DateTime.utc(2030, 5),
      );

      final cutoff = DateTime.utc(2030, 5);
      final upcoming =
          await appointments.listUpcomingForPerson(alexId, now: cutoff);
      final past =
          await appointments.listPastForPerson(alexId, now: cutoff);

      expect(upcoming.map((a) => a.id), [exactly.id]);
      expect(past, isEmpty);
    });
  });

  group('update', () {
    test('persists new fields, bumps rowVersion, stamps updatedAt', () async {
      final created = await appointments.create(
        personId: alexId,
        title: 'Before',
        scheduledAt: DateTime.utc(2030, 6, 1, 10),
      );

      final updated = await appointments.update(
        created.copyWith(
          title: 'After',
          scheduledAt: DateTime.utc(2030, 6, 1, 11),
          reminderLeadMinutes: 120,
        ),
      );

      expect(updated.title, 'After');
      expect(updated.scheduledAt, DateTime.utc(2030, 6, 1, 11));
      expect(updated.reminderLeadMinutes, 120);
      expect(updated.rowVersion, 2);
      expect(
        updated.updatedAt.isAfter(created.updatedAt),
        isTrue,
        reason: 'updatedAt should advance on every write',
      );

      final reloaded = await appointments.findById(created.id);
      expect(reloaded!.title, 'After');
      expect(reloaded.scheduledAt, DateTime.utc(2030, 6, 1, 11));
    });

    test('refuses to change personId', () async {
      final other = await people.create(displayName: 'Sibling');
      final created = await appointments.create(
        personId: alexId,
        title: 'x',
        scheduledAt: DateTime.utc(2030, 6),
      );
      expect(
        () => appointments.update(created.copyWith(personId: other.id)),
        throwsA(isA<StateError>()),
      );
    });

    test('throws AppointmentNotFoundError for an unknown id', () async {
      final stranger = await people.create(displayName: 'Temp');
      final temp = await appointments.create(
        personId: stranger.id,
        title: 'x',
        scheduledAt: DateTime.utc(2030, 6),
      );
      final ghost = temp.copyWith(id: 'does-not-exist');
      expect(
        () => appointments.update(ghost),
        throwsA(isA<AppointmentNotFoundError>()),
      );
    });
  });

  group('archive / restore', () {
    test('archive moves the row out of upcoming and into archived', () async {
      final a = await appointments.create(
        personId: alexId,
        title: 'to be archived',
        scheduledAt: DateTime.utc(2030, 6),
      );
      await appointments.archive(a.id);

      final upcoming = await appointments.listUpcomingForPerson(
        alexId,
        now: DateTime.utc(2030),
      );
      expect(upcoming, isEmpty);

      final archived = await appointments.listArchivedForPerson(alexId);
      expect(archived.map((x) => x.id), [a.id]);
      expect(archived.single.deletedAt, isNotNull);
    });

    test('double-archive throws', () async {
      final a = await appointments.create(
        personId: alexId,
        title: 'x',
        scheduledAt: DateTime.utc(2030, 6),
      );
      await appointments.archive(a.id);
      expect(
        () => appointments.archive(a.id),
        throwsA(isA<AppointmentNotFoundError>()),
      );
    });

    test('restore un-archives and throws on not-archived rows', () async {
      final a = await appointments.create(
        personId: alexId,
        title: 'x',
        scheduledAt: DateTime.utc(2030, 6),
      );
      await appointments.archive(a.id);
      await appointments.restore(a.id);

      final archived = await appointments.listArchivedForPerson(alexId);
      expect(archived, isEmpty);

      expect(
        () => appointments.restore(a.id),
        throwsA(isA<AppointmentNotFoundError>()),
      );
    });
  });
}
