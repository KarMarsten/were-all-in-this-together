import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/reports/data/adherence_report_service.dart';
import 'package:were_all_in_this_together/features/reports/domain/adherence_report_row.dart';
import 'package:were_all_in_this_together/features/reports/presentation/adherence_report_screen.dart';

/// In-memory double for [AdherenceReportService]. Tests pin down the
/// shape of the rows it returns rather than touching the encrypted
/// repositories.
class _FakeService implements AdherenceReportService {
  _FakeService(this.rowsByQueryKey);

  /// Keyed by a string representation of the query so we can return
  /// different rows for different filter combinations.
  final Map<String, List<AdherenceReportRow>> rowsByQueryKey;
  final List<AdherenceReportQuery> recordedQueries = [];

  @override
  Future<List<AdherenceReportRow>> fetch(AdherenceReportQuery query) async {
    recordedQueries.add(query);
    final from = query.fromInclusive.toIso8601String();
    final to = query.toExclusive.toIso8601String();
    final key = '$from|$to|${query.personId ?? ''}';
    return rowsByQueryKey[key] ?? rowsByQueryKey['*'] ?? const [];
  }
}

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: AdherenceReportScreen()),
    );

void main() {
  testWidgets('renders empty state when no rows', (tester) async {
    await tester.pumpWidget(
      _wrap([
        peopleListProvider.overrideWith((ref) async => const <Person>[]),
        adherenceReportServiceProvider
            .overrideWith((_) => _FakeService({'*': const []})),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adherence report'), findsOneWidget);
    expect(find.text('No doses logged in this range.'), findsOneWidget);
  });

  testWidgets('renders rows with all four columns', (tester) async {
    final row = AdherenceReportRow(
      scheduledAt: DateTime.utc(2026, 4, 18, 8),
      loggedAt: DateTime.utc(2026, 4, 18, 8, 5),
      personId: 'p1',
      personName: 'Alex',
      medicationId: 'm1',
      medicationName: 'Methylphenidate',
      outcome: DoseOutcome.taken,
      ackedBy: 'This device',
    );

    await tester.pumpWidget(
      _wrap([
        peopleListProvider.overrideWith((ref) async => const <Person>[]),
        adherenceReportServiceProvider.overrideWith(
          (_) => _FakeService({'*': [row]}),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Person'), findsOneWidget);
    expect(find.text("ACK'd by"), findsOneWidget);

    expect(find.textContaining('Methylphenidate'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
  });

  testWidgets('share + print are disabled when the report is empty',
      (tester) async {
    await tester.pumpWidget(
      _wrap([
        peopleListProvider.overrideWith((ref) async => const <Person>[]),
        adherenceReportServiceProvider
            .overrideWith((_) => _FakeService({'*': const []})),
      ]),
    );
    await tester.pumpAndSettle();

    final share = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share),
    );
    final print = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.print_outlined),
    );
    expect(share.onPressed, isNull);
    expect(print.onPressed, isNull);
  });

  testWidgets('share + print are enabled when there are rows',
      (tester) async {
    final row = AdherenceReportRow(
      scheduledAt: DateTime.utc(2026, 4, 18, 8),
      loggedAt: DateTime.utc(2026, 4, 18, 8, 5),
      personId: 'p1',
      personName: 'Alex',
      medicationId: 'm1',
      medicationName: 'Methylphenidate',
      outcome: DoseOutcome.taken,
      ackedBy: 'This device',
    );

    await tester.pumpWidget(
      _wrap([
        peopleListProvider.overrideWith((ref) async => const <Person>[]),
        adherenceReportServiceProvider
            .overrideWith((_) => _FakeService({'*': [row]})),
      ]),
    );
    await tester.pumpAndSettle();

    final share = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share),
    );
    final print = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.print_outlined),
    );
    expect(share.onPressed, isNotNull);
    expect(print.onPressed, isNotNull);
  });

  testWidgets('Who dropdown lists Everyone + every Person',
      (tester) async {
    final alex = Person(
      id: 'p1',
      displayName: 'Alex',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final jamie = Person(
      id: 'p2',
      displayName: 'Jamie',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      _wrap([
        peopleListProvider.overrideWith((ref) async => [alex, jamie]),
        adherenceReportServiceProvider
            .overrideWith((_) => _FakeService({'*': const []})),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();

    // Both the dropdown's visible entry and the menu entry exist.
    expect(find.text('Everyone'), findsWidgets);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Jamie'), findsOneWidget);
  });
}
