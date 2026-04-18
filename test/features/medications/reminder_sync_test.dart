import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` isn't exported from the flutter_riverpod barrel in 3.x —
// same workaround used elsewhere in this repo's test helpers.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/core/notifications/local_notification_service.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/notification_preferences_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/in_memory_key_storage.dart';

/// End-to-end proof that medication mutations actually propagate into
/// the notification service via [reminderSyncProvider].
///
/// This exercises the whole wire from repository → providers →
/// reconciler → service fake. If the `invalidateMedicationsState` list
/// ever forgets to invalidate `allActiveMedicationsProvider` again,
/// this test is the one that should fail first.
void main() {
  late ProviderContainer container;
  late FakeNotificationService fake;

  setUp(() {
    fake = FakeNotificationService();
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
        keyStorageProvider.overrideWith((_) => InMemoryKeyStorage()),
        notificationServiceProvider.overrideWith((_) => fake),
        // Default prefs — SharedPreferences isn't wired in unit tests,
        // so override the FutureProvider to resolve synchronously.
        notificationPreferencesProvider
            .overrideWith((_) async => const NotificationPreferences()),
      ],
    )
      // Subscribe to the sync provider; without this the `ref.listen`
      // inside it is never instantiated and reconciliation never
      // runs. `App` does the equivalent watch in production.
      ..read(reminderSyncProvider);
  });

  tearDown(() => container.dispose());

  Future<void> flush() async {
    // The reminder-sync listener dispatches reconciliation via a
    // fire-and-forget `unawaited`, so the test has to let the
    // microtask + event queue drain before asserting. Two rounds is
    // enough for: invalidate → re-fetch → reconcile → record.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
      'creating a medication with a daily schedule schedules one reminder '
      'per time on the fake service', () async {
    final peopleRepo = container.read(personRepositoryProvider);
    final medsRepo = container.read(medicationRepositoryProvider);

    final alex = await peopleRepo.create(displayName: 'Alex');
    container.invalidate(peopleListProvider);
    await container.read(allActiveMedicationsProvider.future);

    await medsRepo.create(
      personId: alex.id,
      name: 'Methylphenidate',
      dose: '10mg',
      schedule: const MedicationSchedule(
        kind: ScheduleKind.daily,
        times: [
          ScheduledTime(hour: 8, minute: 0),
          ScheduledTime(hour: 20, minute: 0),
        ],
      ),
    );

    // Poke the same invalidation path the UI uses after a write —
    // the repository call alone doesn't invalidate providers.
    container.invalidate(allActiveMedicationsProvider);
    await container.read(allActiveMedicationsProvider.future);
    await flush();

    // The reconciler now emits a per-instance chain (initial + nag
    // cap=3) for every dose in the 48h window. Two times × two days
    // × four reminders = 16 reminders; every one should be tagged
    // "Alex · …" and cover both 08:00 and 20:00 local slots.
    expect(fake.scheduled, hasLength(16));
    expect(fake.scheduled.every((r) => r.title.startsWith('Alex · ')), isTrue);
    final localHours =
        fake.scheduled.map((r) => r.scheduledAt.toLocal().hour).toSet();
    expect(localHours, containsAll(<int>[8, 20]));
  });

  test('archiving the only medication cancels its reminder', () async {
    final peopleRepo = container.read(personRepositoryProvider);
    final medsRepo = container.read(medicationRepositoryProvider);

    final alex = await peopleRepo.create(displayName: 'Alex');
    container.invalidate(peopleListProvider);
    await container.read(allActiveMedicationsProvider.future);

    final med = await medsRepo.create(
      personId: alex.id,
      name: 'Methylphenidate',
      schedule: const MedicationSchedule(
        kind: ScheduleKind.daily,
        times: [ScheduledTime(hour: 8, minute: 0)],
      ),
    );
    container.invalidate(allActiveMedicationsProvider);
    await container.read(allActiveMedicationsProvider.future);
    await flush();
    // Initial + nag chain for 2 dose instances = 8 reminders.
    expect(fake.scheduled, hasLength(8));
    final reminderIds = fake.scheduled.map((r) => r.id).toList();

    await medsRepo.archive(med.id);
    container.invalidate(allActiveMedicationsProvider);
    await container.read(allActiveMedicationsProvider.future);
    await flush();

    expect(fake.scheduled, isEmpty);
    for (final id in reminderIds) {
      expect(fake.cancelCalls, contains(id));
    }
  });
}
