import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

import '../../helpers/test_app_scope.dart';

/// Pinned "now" for the widget test so the expander + clock agree on
/// which day it is and which doses are past / upcoming regardless of
/// the host TZ. Picked as a Saturday local afternoon.
final _fakeNow = DateTime(2026, 4, 18, 14);

DateTime _clock() => _fakeNow;

/// Seed the test DB by reaching into the provider container after the
/// first pump. Pulls the repos out the same way production code does
/// and drives them directly — no UI ceremony required for setup.
Future<void> _seedMedWithMorningDose(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(App)),
  );
  final peopleRepo = container.read(personRepositoryProvider);
  final medsRepo = container.read(medicationRepositoryProvider);

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

  // Mirror what `invalidatePeopleState` / `invalidateMedicationsState`
  // would do for us if we were going through the UI. Without these the
  // providers still hold their initial (empty) AsyncValues.
  container
    ..invalidate(peopleListProvider)
    ..invalidate(activePersonIdProvider)
    ..invalidate(activePersonProvider)
    ..invalidate(allActiveMedicationsProvider)
    ..invalidate(todayScheduledDosesProvider)
    ..invalidate(todayDoseLogsProvider);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state when there are no scheduled doses today',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [
          todayClockProvider.overrideWith((_) => _clock),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    expect(find.text('Nothing scheduled today'), findsOneWidget);
  });

  testWidgets('renders a dose, marks it taken, then undoes it',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [
          todayClockProvider.overrideWith((_) => _clock),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _seedMedWithMorningDose(tester);

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    // Header + the dose row.
    expect(find.textContaining('Saturday'), findsOneWidget);
    expect(find.text('Methylphenidate · 10mg'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    // 8am is earlier than 2pm fake-now, so the past hint should show.
    expect(find.text('earlier'), findsOneWidget);

    await tester.tap(find.text('Taken'));
    await tester.pumpAndSettle();

    // Row flips to logged state.
    expect(find.text('Taken'), findsOneWidget); // now a label, not a button
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Back to unlogged buttons.
    expect(find.widgetWithText(FilledButton, 'Taken'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
  });
}
