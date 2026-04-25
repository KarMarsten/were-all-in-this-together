import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';

/// Babysitter / respite style handoff: baselines, active structured lines
/// (grouped by section), and national crisis resources.
Future<List<int>> buildCareSummaryPdf({
  required String personName,
  required List<ProfileEntry> activeEntries,
  List<CareProvider> providers = const <CareProvider>[],
  List<Program> programs = const <Program>[],
  List<AppSite> appSites = const <AppSite>[],
  Profile? profile,
  CareSummaryOptions options = const CareSummaryOptions(),
  DateTime? generatedAt,
}) async {
  final generated = (generatedAt ?? DateTime.now()).toUtc();
  final dateFmt = DateFormat.yMMMd();
  final calmWidgets = options.includeCalm
      ? _calmBlock(activeEntries)
      : <pw.Widget>[];
  final baselineWidgets = options.includeBaselines
      ? _baselineBlock(profile)
      : <pw.Widget>[];
  final structuredWidgets = options.includeStructuredProfile
      ? _buildStructuredSections(activeEntries)
      : <pw.Widget>[];
  final providerWidgets = options.includeProviders
      ? _providersBlock(providers)
      : <pw.Widget>[];
  final programWidgets = options.includePrograms
      ? _programsBlock(programs)
      : <pw.Widget>[];
  final appSiteWidgets = options.includeAppSites
      ? _appSitesBlock(appSites)
      : <pw.Widget>[];
  final crisisWidgets = options.includeCrisisResources
      ? _crisisResourcesBlock()
      : <pw.Widget>[];

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
          ...calmWidgets,
          if (calmWidgets.isNotEmpty) pw.SizedBox(height: 16),
          ...baselineWidgets,
          if (baselineWidgets.isNotEmpty) pw.SizedBox(height: 16),
          ...structuredWidgets,
          if (structuredWidgets.isNotEmpty) pw.SizedBox(height: 16),
          ...providerWidgets,
          if (providerWidgets.isNotEmpty) pw.SizedBox(height: 16),
          ...programWidgets,
          if (programWidgets.isNotEmpty) pw.SizedBox(height: 16),
          ...appSiteWidgets,
          if (appSiteWidgets.isNotEmpty && crisisWidgets.isNotEmpty)
            pw.SizedBox(height: 20),
          ...crisisWidgets,
        ],
      ),
    );
  return doc.save();
}

/// User-selectable sections for the care-summary export.
class CareSummaryOptions {
  const CareSummaryOptions({
    this.includeCalm = true,
    this.includeBaselines = true,
    this.includeStructuredProfile = true,
    this.includeProviders = true,
    this.includePrograms = true,
    this.includeAppSites = true,
    this.includeCrisisResources = true,
  });

  final bool includeCalm;
  final bool includeBaselines;
  final bool includeStructuredProfile;
  final bool includeProviders;
  final bool includePrograms;
  final bool includeAppSites;
  final bool includeCrisisResources;

  bool get hasAnySection =>
      includeCalm ||
      includeBaselines ||
      includeStructuredProfile ||
      includeProviders ||
      includePrograms ||
      includeAppSites ||
      includeCrisisResources;
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

List<pw.Widget> _calmBlock(List<ProfileEntry> active) {
  final sections = [
    ProfileEntrySection.earlySign,
    ProfileEntrySection.trigger,
    ProfileEntrySection.whatHelps,
  ];
  final calmEntries = active
      .where((e) => sections.contains(e.section))
      .toList()
    ..sort((a, b) {
      final bySection = sections
          .indexOf(a.section)
          .compareTo(sections.indexOf(b.section));
      if (bySection != 0) return bySection;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });

  final out = <pw.Widget>[
    pw.Text(
      'Calm quick guide',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
  ];

  if (calmEntries.isEmpty) {
    out.add(
      pw.Text(
        'No active early signs, triggers, or what-helps lines yet.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
    return out;
  }

  ProfileEntrySection? currentSection;
  for (final entry in calmEntries) {
    if (entry.section != currentSection) {
      currentSection = entry.section;
      out
        ..add(pw.SizedBox(height: 6))
        ..add(
          pw.Text(
            labelForProfileEntrySection(entry.section),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
        )
        ..add(pw.SizedBox(height: 4));
    }
    final details = entry.details?.trim();
    out.add(
      _pdfBullet(
        details == null || details.isEmpty
            ? entry.label
            : '${entry.label}: $details',
      ),
    );
  }
  return out;
}

List<pw.Widget> _crisisResourcesBlock() {
  return [
    pw.Text(
      'If you need more help',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 8),
    _pdfBullet(
      'If there is immediate danger, call local emergency services.',
    ),
    _pdfBullet(
      '988 — Suicide & Crisis Lifeline (US, call or text).',
    ),
    _pdfBullet('Text HOME to 741741 — Crisis Text Line (US/Canada).'),
    _pdfBullet(
      'Use the Providers list in the app for care-team numbers and portals.',
    ),
    _pdfBullet(
      'For school, camp, or respite handoff: share this summary with a trusted '
      'adult who can act on it.',
    ),
  ];
}

List<pw.Widget> _providersBlock(List<CareProvider> providers) {
  final sorted = [...providers]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final out = <pw.Widget>[
    pw.Text(
      'Providers',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
  ];
  if (sorted.isEmpty) {
    out.add(
      pw.Text(
        'No active providers yet.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
    return out;
  }
  for (final provider in sorted) {
    out.add(
      _summaryEntry(
        title: provider.name,
        subtitle: _joinParts([
              _labelForProviderKind(provider.kind),
              provider.specialty,
              provider.role,
            ]) ??
            _labelForProviderKind(provider.kind),
        rows: [
          _field('Contact', provider.contactName),
          _field('Phone', provider.phone),
          _field('After-hours phone', provider.afterHoursPhone),
          _field('Email', provider.email),
          _field('Fax', provider.fax),
          _field('Address', provider.address),
          _field(
            provider.portalLabel?.trim().isEmpty ?? true
                ? 'Portal'
                : provider.portalLabel!.trim(),
            provider.portalUrl,
          ),
          _field('After-hours instructions', provider.afterHoursInstructions),
          _field('Notes', provider.notes),
        ],
      ),
    );
  }
  return out;
}

List<pw.Widget> _programsBlock(List<Program> programs) {
  final sorted = [...programs]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final out = <pw.Widget>[
    pw.Text(
      'Programs',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
  ];
  if (sorted.isEmpty) {
    out.add(
      pw.Text(
        'No active programs yet.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
    return out;
  }
  for (final program in sorted) {
    out.add(
      _summaryEntry(
        title: program.name,
        subtitle: labelForProgramKind(program.kind),
        rows: [
          _field(
            'Contact',
            _joinParts([program.contactName, program.contactRole]),
          ),
          _field('Phone', program.phone),
          _field('Email', program.email),
          _field('Address', program.address),
          _field('Website', program.websiteUrl),
          _field('Hours', program.hours),
          _field('Notes', program.notes),
        ],
      ),
    );
  }
  return out;
}

List<pw.Widget> _appSitesBlock(List<AppSite> appSites) {
  final sorted = [...appSites]
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  final out = <pw.Widget>[
    pw.Text(
      'Apps & Sites',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
    pw.Text(
      'No passwords, recovery codes, or security answers are included here.',
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
    ),
    pw.SizedBox(height: 6),
  ];
  if (sorted.isEmpty) {
    out.add(
      pw.Text(
        'No active apps or sites yet.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
    return out;
  }
  for (final site in sorted) {
    out.add(
      _summaryEntry(
        title: site.title,
        subtitle: labelForAppSiteCategory(site.category),
        rows: [
          _field('URL', site.url),
          _field('Username hint', site.usernameHint),
          _field('Login note', site.loginNote),
          _field('Notes', site.notes),
        ],
      ),
    );
  }
  return out;
}

({String label, String value})? _field(String label, String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return (label: label, value: value);
}

pw.Widget _summaryEntry({
  required String title,
  required String subtitle,
  required List<({String label, String value})?> rows,
}) {
  final present = rows.nonNulls.toList();
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1, bottom: 2),
          child: pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        for (final row in present)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
                children: [
                  pw.TextSpan(
                    text: '${row.label}: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: row.value),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

String? _joinParts(Iterable<String?> parts) {
  final out = parts
      .where((p) => p != null && p.trim().isNotEmpty)
      .map((p) => p!.trim())
      .join(', ');
  return out.isEmpty ? null : out;
}

String _labelForProviderKind(CareProviderKind kind) {
  switch (kind) {
    case CareProviderKind.pcp:
      return 'Primary care';
    case CareProviderKind.specialist:
      return 'Specialist';
    case CareProviderKind.therapist:
      return 'Therapist';
    case CareProviderKind.dentist:
      return 'Dental';
    case CareProviderKind.other:
      return 'Other';
  }
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
