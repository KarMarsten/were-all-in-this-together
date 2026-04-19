import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';

/// Babysitter / respite style handoff: baselines, active structured lines
/// (grouped by section), and national crisis resources.
Future<List<int>> buildCareSummaryPdf({
  required String personName,
  required List<ProfileEntry> activeEntries,
  Profile? profile,
  DateTime? generatedAt,
}) async {
  final generated = (generatedAt ?? DateTime.now()).toUtc();
  final dateFmt = DateFormat.yMMMd();
  final sections = _buildStructuredSections(activeEntries);
  final baselineWidgets = _baselineBlock(profile);

  final doc = pw.Document()
    ..addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
        build: (ctx) => [
          pw.Text(
            'Care summary',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            personName,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated ${dateFmt.format(generated)} (UTC)',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 20),
          ...baselineWidgets,
          if (baselineWidgets.isNotEmpty) pw.SizedBox(height: 16),
          ...sections,
          pw.SizedBox(height: 20),
          pw.Text(
            'If you need more help',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _pdfBullet(
            '988 — Suicide & Crisis Lifeline (US, call or text).',
          ),
          _pdfBullet('Text HOME to 741741 — Crisis Text Line.'),
          _pdfBullet(
            'Use the Providers list in the app for your care team numbers.',
          ),
        ],
      ),
    );
  return doc.save();
}

pw.Widget _pdfBullet(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
        pw.Expanded(
          child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );
}

List<pw.Widget> _baselineBlock(Profile? profile) {
  if (profile == null) return [];
  final out = <pw.Widget>[];
  void add(String title, String? raw) {
    final body = raw?.trim();
    if (body == null || body.isEmpty) return;
    out
      ..add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(body, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      )
      ..add(pw.SizedBox(height: 10));
  }

  add('Communication', profile.communicationNotes);
  add('Sleep baseline', profile.sleepBaseline);
  add('Appetite / eating baseline', profile.appetiteBaseline);

  if (out.isEmpty) return [];

  return [
    pw.Text(
      'Baselines',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 8),
    ...out,
  ];
}

List<pw.Widget> _buildStructuredSections(List<ProfileEntry> active) {
  if (active.isEmpty) {
    return [
      pw.Text(
        'Structured profile lines',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'No active structured lines yet — add triggers, what helps, early '
        'signs, and routines in Profile.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    ];
  }

  final out = <pw.Widget>[
    pw.Text(
      'Structured profile lines (active)',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 8),
  ];

  for (final section in ProfileEntrySection.values) {
    final inSection = active.where((e) => e.section == section).toList()
      ..sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
    if (inSection.isEmpty) continue;

    out
      ..add(
        pw.Text(
          labelForProfileEntrySection(section),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal800,
          ),
        ),
      )
      ..add(pw.SizedBox(height: 6));
    for (final e in inSection) {
      final details = e.details?.trim();
      out.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                e.label,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (details != null && details.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    details,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    out.add(pw.SizedBox(height: 6));
  }
  return out;
}
