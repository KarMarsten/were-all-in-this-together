import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

import '../../helpers/test_app_scope.dart';

/// Same pinned Saturday as the appointments Today suite.
final _fakeNow = DateTime(2026, 4, 18, 14);

DateTime _clock() => _fakeNow;

Future<void> _seed(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(App)),
  );
  final peopleRepo = container.read(personRepositoryProvider);
  final medsRepo = container.read(medicationRepositoryProvider);
  final milestonesRepo = container.read(milestoneRepositoryProvider);

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
  await milestonesRepo.create(
    personId: alex.id,
    kind: MilestoneKind.vaccine,
    title: 'Flu shot',
    occurredAt: DateTime.utc(2020, 4, 18),
    precision: MilestonePrecision.day,
  );

  container
    ..invalidate(peopleListProvider)
    ..invalidate(activePersonIdProvider)
    ..invalidate(activePersonProvider)
    ..invalidate(allActiveMedicationsProvider)
    ..invalidate(allTodayMilestonesProvider)
    ..invalidate(todayScheduledDosesProvider)
    ..invalidate(todayItemsProvider)
    ..invalidate(todayDoseLogsProvider);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Today screen renders milestone anniversaries with doses',
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

    expect(find.text('Methylphenidate · 10mg'), findsOneWidget);
    expect(find.text('Flu shot'), findsOneWidget);
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.textContaining('6 years ago'), findsOneWidget);
  });

  testWidgets('tapping a milestone tile opens its edit screen',
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

    await tester.tap(find.text('Flu shot'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Flu shot'), findsOneWidget);
  });
}
