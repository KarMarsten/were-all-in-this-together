import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

import '../../helpers/test_app_scope.dart';

final _fakeNow = DateTime(2026, 4, 18, 7);
DateTime _clock() => _fakeNow;

Future<List<String>> _seedGroupWithTwoMeds(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(App)),
  );
  final peopleRepo = container.read(personRepositoryProvider);
  final medsRepo = container.read(medicationRepositoryProvider);
  final groupsRepo = container.read(medicationGroupRepositoryProvider);

  final alex = await peopleRepo.create(displayName: 'Alex');
  final aspirin = await medsRepo.create(
    personId: alex.id,
    name: 'Aspirin',
    dose: '81mg',
    form: MedicationForm.pill,
  );
  final vitaminD = await medsRepo.create(
    personId: alex.id,
    name: 'Vitamin D',
    form: MedicationForm.pill,
  );
  await groupsRepo.create(
    personId: alex.id,
    name: 'Morning stack',
    schedule: const MedicationSchedule(
      kind: ScheduleKind.daily,
      times: [ScheduledTime(hour: 8, minute: 0)],
    ),
    memberMedicationIds: [aspirin.id, vitaminD.id],
  );

  container
    ..invalidate(peopleListProvider)
    ..invalidate(activePersonIdProvider)
    ..invalidate(activePersonProvider)
    ..invalidate(allActiveMedicationsProvider)
    ..invalidate(allActiveMedicationGroupsProvider)
    ..invalidate(todayItemsProvider)
    ..invalidate(todayDoseLogsProvider);
  await tester.pumpAndSettle();

  return [aspirin.id, vitaminD.id];
}

void main() {
  testWidgets('renders a group bundle row with member count', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [todayClockProvider.overrideWith((_) => _clock)],
      ),
    );
    await tester.pumpAndSettle();

    await _seedGroupWithTwoMeds(tester);

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    expect(find.text('Morning stack'), findsOneWidget);
    expect(find.textContaining('2 meds'), findsOneWidget);
  });

  testWidgets('tapping Taken on a group logs every member then Undo clears',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        extraOverrides: [todayClockProvider.overrideWith((_) => _clock)],
      ),
    );
    await tester.pumpAndSettle();

    final memberIds = await _seedGroupWithTwoMeds(tester);

    await tester.tap(find.text("Today's doses"));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Taken'));
    await tester.pumpAndSettle();

    // Bundle flips to logged — "all taken" summary and an Undo button.
    expect(find.textContaining('all taken'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Verify the repo wrote one log per member at 08:00 local.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    final logsRepo = container.read(doseLogRepositoryProvider);
    final scheduledAt = DateTime(2026, 4, 18, 8).toUtc();
    final logs = await logsRepo.forMedicationsInRange(
      medicationIds: memberIds,
      fromInclusive: scheduledAt.subtract(const Duration(hours: 1)),
      toExclusive: scheduledAt.add(const Duration(hours: 1)),
    );
    expect(logs, hasLength(2));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Both rows return to the pending state.
    expect(find.widgetWithText(FilledButton, 'Taken'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);

    final logsAfterUndo = await logsRepo.forMedicationsInRange(
      medicationIds: memberIds,
      fromInclusive: scheduledAt.subtract(const Duration(hours: 1)),
      toExclusive: scheduledAt.add(const Duration(hours: 1)),
    );
    expect(logsAfterUndo, isEmpty);
  });
}
