import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/reports/data/adherence_report_pdf.dart';
import 'package:were_all_in_this_together/features/reports/domain/adherence_report_row.dart';

void main() {
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

  test('produces a non-empty PDF with the expected magic bytes', () async {
    final bytes = await buildAdherenceReportPdf(
      rows: [row],
      fromInclusive: DateTime.utc(2026, 4),
      toExclusive: DateTime.utc(2026, 5),
    );

    expect(bytes, isNotEmpty);
    final prefix = Uint8List.fromList(bytes.sublist(0, 5));
    expect(prefix, equals(Uint8List.fromList(const [37, 80, 68, 70, 45])));
  });

  test('produces a PDF even when there are no rows', () async {
    final bytes = await buildAdherenceReportPdf(
      rows: const [],
      fromInclusive: DateTime.utc(2026, 4),
      toExclusive: DateTime.utc(2026, 5),
    );
    expect(bytes, isNotEmpty);
  });
}
