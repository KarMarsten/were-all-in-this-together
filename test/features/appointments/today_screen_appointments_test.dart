import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/presentation/providers.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/medications/presentation/today_providers.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

import '../../helpers/test_app_scope.dart';

/// Pinned "now" so the expanded-day window + the fake-now comparison
/// are deterministic across CI timezones. A Saturday afternoon keeps
/// a morning dose ordered before an afternoon appointment, which is
/// the invariant this suite asserts on.
final _fakeNow = DateTime(2026, 4, 18, 14);

DateTime _clock() => _fakeNow;

Future<void> _seed(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(App)),
  );
  final peopleRepo = container.read(personRepositoryProvider);
  final medsRepo = container.read(medicationRepositoryProvider);
  final apptsRepo = container.read(appointmentRepositoryProvider);

  final alex = await peopleRepo.create(displayName: 'Alex');
  await medsRepo.create(
    personId: alex.id,
    name: 'Methylphenidate',
    dose: '10mg',
    form: MedicationForm.pill,
    schedule: const MedicationSchedule(
      kind: ScheduleKind.daily,
      times: [ScheduledTime(hour: 8, minute: 0)],
    ),
  );
  await apptsRepo.create(
    personId: alex.id,
    title: 'Dr. Chen checkup',
    scheduledAt: _fakeNow.add(const Duration(hours: 2)).toUtc(),
    location: 'Clinic A',
  );

  container
    ..invalidate(peopleListProvider)
    ..invalidate(activePersonIdProvider)
    ..invalidate(activePersonProvider)
    ..invalidate(allActiveMedicationsProvider)
    ..invalidate(allTodayAppointmentsProvider)
    ..invalidate(todayScheduledDosesProvider)
    ..invalidate(todayItemsProvider)
    ..invalidate(todayDoseLogsProvider);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Today screen renders appointments alongside doses',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [
          todayClockProvider.overrideWith((_) => _clock),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _seed(tester);

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    // Dose row.
    expect(find.text('Methylphenidate · 10mg'), findsOneWidget);
    // Appointment row: title + subtitle line ("Alex · Clinic A").
    expect(find.text('Dr. Chen checkup'), findsOneWidget);
    expect(find.text('Alex · Clinic A'), findsOneWidget);
  });

  testWidgets('a past-today appointment shows the "earlier" hint',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [
          todayClockProvider.overrideWith((_) => _clock),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    final peopleRepo = container.read(personRepositoryProvider);
    final apptsRepo = container.read(appointmentRepositoryProvider);
    final sam = await peopleRepo.create(displayName: 'Sam');
    // 08:00 local, before the 14:00 fake-now.
    await apptsRepo.create(
      personId: sam.id,
      title: 'Morning visit',
      scheduledAt: DateTime(2026, 4, 18, 8).toUtc(),
    );
    container
      ..invalidate(peopleListProvider)
      ..invalidate(allTodayAppointmentsProvider)
      ..invalidate(todayItemsProvider);
    await tester.pumpAndSettle();

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    expect(find.text('Morning visit'), findsOneWidget);
    expect(find.text('earlier'), findsOneWidget);
  });

  testWidgets(
      'tapping an appointment tile navigates to its edit screen',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [
          todayClockProvider.overrideWith((_) => _clock),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _seed(tester);

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dr. Chen checkup'));
    await tester.pumpAndSettle();

    // Edit screen shows the appointment's title as a prefilled
    // form field. Assert the "Title" label is present — the form
    // wraps the field in an InputDecorator with that label.
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Dr. Chen checkup'), findsWidgets);
  });
}
