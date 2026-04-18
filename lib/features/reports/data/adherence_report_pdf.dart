import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/reports/domain/adherence_report_row.dart';

/// Build a paginated adherence-report PDF from [rows].
///
/// The output is intentionally plain: a title, the date range, a
/// four-column table, and a footer with totals. No logos, no colour
/// theming — this is a document a caregiver might print for a
/// pediatrician, and the priority is readability + photocopy
/// robustness, not brand.
///
/// The exported bytes are `Uint8List` rather than `pw.Document`
/// because the caller path (share, print, save) always wants raw
/// bytes — wrapping in a document just adds a hop.
Future<List<int>> buildAdherenceReportPdf({
  required List<AdherenceReportRow> rows,
  required DateTime fromInclusive,
  required DateTime toExclusive,
  String? personName,
  DateTime? generatedAt,
}) async {
  final doc = pw.Document()
    ..addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
        header: (ctx) => _buildHeader(
          fromInclusive: fromInclusive,
          // Render the inclusive end day — the query uses an exclusive
          // upper bound but readers expect "Jan 1 → Jan 7" to include
          // Jan 7.
          toInclusive: toExclusive.subtract(const Duration(seconds: 1)),
          personName: personName,
        ),
        footer: _buildFooter,
        build: (ctx) => [
          _buildTable(rows),
          pw.SizedBox(height: 16),
          _buildSummary(
            rows,
            generatedAt: (generatedAt ?? DateTime.now()).toUtc(),
          ),
        ],
      ),
    );
  return doc.save();
}

pw.Widget _buildHeader({
  required DateTime fromInclusive,
  required DateTime toInclusive,
  String? personName,
}) {
  final dateFmt = DateFormat.yMMMd();
  final from = dateFmt.format(fromInclusive.toLocal());
  final to = dateFmt.format(toInclusive.toLocal());
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Medication adherence report',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        personName == null ? '$from - $to' : '$from - $to  /  $personName',
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      pw.Divider(height: 1, color: PdfColors.grey400),
      pw.SizedBox(height: 12),
    ],
  );
}

pw.Widget _buildFooter(pw.Context ctx) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    padding: const pw.EdgeInsets.only(top: 8),
    child: pw.Text(
      'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
    ),
  );
}

pw.Widget _buildTable(List<AdherenceReportRow> rows) {
  if (rows.isEmpty) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      alignment: pw.Alignment.center,
      child: pw.Text(
        'No doses logged in this date range.',
        style:
            pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey),
      ),
    );
  }

  final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final headers = <String>['Time', 'Medication', 'Person', "ACK'd by"];

  final data = <List<String>>[
    for (final r in rows)
      [
        dateFmt.format(r.scheduledAt.toLocal()),
        r.medicationName +
            (r.outcome == DoseOutcome.skipped ? '  (skipped)' : ''),
        r.personName,
        r.ackedBy,
      ],
  ];

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    cellStyle: const pw.TextStyle(fontSize: 10),
    cellAlignment: pw.Alignment.centerLeft,
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.2),
      1: pw.FlexColumnWidth(3),
      2: pw.FlexColumnWidth(2),
      3: pw.FlexColumnWidth(2),
    },
  );
}

pw.Widget _buildSummary(
  List<AdherenceReportRow> rows, {
  required DateTime generatedAt,
}) {
  final taken = rows.where((r) => r.outcome == DoseOutcome.taken).length;
  final skipped = rows.where((r) => r.outcome == DoseOutcome.skipped).length;
  final generatedFmt = DateFormat('yyyy-MM-dd HH:mm');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Totals',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Doses logged: ${rows.length}   Taken: $taken   Skipped: $skipped',
        style: const pw.TextStyle(fontSize: 10),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Generated ${generatedFmt.format(generatedAt.toLocal())}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    ],
  );
}
