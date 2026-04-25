import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/apps_sites/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/providers.dart';
import 'package:were_all_in_this_together/features/reports/data/care_summary_pdf.dart';

/// PDF handoff: baselines + active structured profile + Calm guide + resources.
class CareSummaryScreen extends ConsumerStatefulWidget {
  const CareSummaryScreen({super.key});

  @override
  ConsumerState<CareSummaryScreen> createState() => _CareSummaryScreenState();
}

class _CareSummaryScreenState extends ConsumerState<CareSummaryScreen> {
  bool _includeCalm = true;
  bool _includeBaselines = true;
  bool _includeStructuredProfile = true;
  bool _includePrograms = true;
  bool _includeAppSites = true;
  bool _includeCrisisResources = true;

  CareSummaryOptions get _options => CareSummaryOptions(
        includeCalm: _includeCalm,
        includeBaselines: _includeBaselines,
        includeStructuredProfile: _includeStructuredProfile,
        includePrograms: _includePrograms,
        includeAppSites: _includeAppSites,
        includeCrisisResources: _includeCrisisResources,
      );

  Future<Uint8List> _buildBytes(WidgetRef ref) async {
    final person = await ref.read(activePersonProvider.future);
    if (person == null) {
      throw StateError('No active person');
    }
    final profile = await ref.read(activePersonProfileProvider.future);
    final all = await ref.read(profileEntriesForActivePersonProvider.future);
    final programs = await ref.read(activeProgramsProvider.future);
    final appSites = await ref.read(activeAppSitesProvider.future);
    final active = all
        .where((e) => e.status == ProfileEntryStatus.active)
        .toList();
    final raw = await buildCareSummaryPdf(
      personName: person.displayName,
      activeEntries: active,
      programs: programs,
      appSites: appSites,
      profile: profile,
      options: _options,
    );
    return Uint8List.fromList(raw);
  }

  String _filename(String personName) {
    final slug = personName
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final safe = slug.isEmpty ? 'person' : slug;
    return 'care-summary-$safe-$day.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final personAsync = ref.watch(activePersonProvider);
    final entriesAsync = ref.watch(profileEntriesForActivePersonProvider);
    final profileAsync = ref.watch(activePersonProfileProvider);
    final programsAsync = ref.watch(activeProgramsProvider);
    final appSitesAsync = ref.watch(activeAppSitesProvider);
    final canExport = personAsync.hasValue &&
        personAsync.value != null &&
        _options.hasAnySection;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care summary'),
        actions: [
          IconButton(
            tooltip: 'Share or save as PDF',
            icon: const Icon(Icons.ios_share),
            onPressed: canExport
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final person = personAsync.value!;
                      final bytes = await _buildBytes(ref);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: _filename(person.displayName),
                      );
                    } on Object catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Couldn't build PDF: $e")),
                      );
                    }
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_outlined),
            onPressed: canExport
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final bytes = await _buildBytes(ref);
                      await Printing.layoutPdf(onLayout: (_) async => bytes);
                    } on Object catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Couldn't print: $e")),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (person) {
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Pick someone on Home first — the summary follows the '
                  'active person.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'For babysitters, grandparents, and respite',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Choose what to include, then export a short handoff PDF. '
                'Paused or resolved profile lines stay in the app but are '
                'omitted here.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _IncludeOptionsCard(
                includeCalm: _includeCalm,
                includeBaselines: _includeBaselines,
                includeStructuredProfile: _includeStructuredProfile,
                includePrograms: _includePrograms,
                includeAppSites: _includeAppSites,
                includeCrisisResources: _includeCrisisResources,
                onCalmChanged: (v) => setState(() => _includeCalm = v),
                onBaselinesChanged: (v) =>
                    setState(() => _includeBaselines = v),
                onStructuredChanged: (v) =>
                    setState(() => _includeStructuredProfile = v),
                onProgramsChanged: (v) =>
                    setState(() => _includePrograms = v),
                onAppSitesChanged: (v) =>
                    setState(() => _includeAppSites = v),
                onCrisisChanged: (v) =>
                    setState(() => _includeCrisisResources = v),
              ),
              const SizedBox(height: 16),
              _PreviewCard(
                entriesAsync: entriesAsync,
                profileAsync: profileAsync,
                programsAsync: programsAsync,
                appSitesAsync: appSitesAsync,
                options: _options,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: canExport
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final bytes = await _buildBytes(ref);
                          await Printing.sharePdf(
                            bytes: bytes,
                            filename: _filename(person.displayName),
                          );
                        } on Object catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text("Couldn't build PDF: $e")),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Share PDF'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IncludeOptionsCard extends StatelessWidget {
  const _IncludeOptionsCard({
    required this.includeCalm,
    required this.includeBaselines,
    required this.includeStructuredProfile,
    required this.includePrograms,
    required this.includeAppSites,
    required this.includeCrisisResources,
    required this.onCalmChanged,
    required this.onBaselinesChanged,
    required this.onStructuredChanged,
    required this.onProgramsChanged,
    required this.onAppSitesChanged,
    required this.onCrisisChanged,
  });

  final bool includeCalm;
  final bool includeBaselines;
  final bool includeStructuredProfile;
  final bool includePrograms;
  final bool includeAppSites;
  final bool includeCrisisResources;
  final ValueChanged<bool> onCalmChanged;
  final ValueChanged<bool> onBaselinesChanged;
  final ValueChanged<bool> onStructuredChanged;
  final ValueChanged<bool> onProgramsChanged;
  final ValueChanged<bool> onAppSitesChanged;
  final ValueChanged<bool> onCrisisChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                'Include in PDF',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile(
              value: includeCalm,
              onChanged: onCalmChanged,
              title: const Text('Calm quick guide'),
              subtitle: const Text('Early signs, triggers, and what helps.'),
            ),
            SwitchListTile(
              value: includeBaselines,
              onChanged: onBaselinesChanged,
              title: const Text('Baselines'),
              subtitle: const Text('Communication, sleep, and appetite.'),
            ),
            SwitchListTile(
              value: includeStructuredProfile,
              onChanged: onStructuredChanged,
              title: const Text('Structured profile lines'),
              subtitle: const Text('Active profile entries by section.'),
            ),
            SwitchListTile(
              value: includePrograms,
              onChanged: onProgramsChanged,
              title: const Text('Programs'),
              subtitle: const Text('School, camp, after-care contacts.'),
            ),
            SwitchListTile(
              value: includeAppSites,
              onChanged: onAppSitesChanged,
              title: const Text('Apps & Sites'),
              subtitle: const Text('URLs and login hints, never passwords.'),
            ),
            SwitchListTile(
              value: includeCrisisResources,
              onChanged: onCrisisChanged,
              title: const Text('Support resources'),
              subtitle: const Text('Emergency, 988, text line, and care team.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.entriesAsync,
    required this.profileAsync,
    required this.programsAsync,
    required this.appSitesAsync,
    required this.options,
  });

  final AsyncValue<List<ProfileEntry>> entriesAsync;
  final AsyncValue<Profile?> profileAsync;
  final AsyncValue<List<Program>> programsAsync;
  final AsyncValue<List<AppSite>> appSitesAsync;
  final CareSummaryOptions options;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: entriesAsync.when(
          loading: () => const Text('Loading preview...'),
          error: (e, _) => Text("Couldn't load preview: $e"),
          data: (entries) {
            final active = entries
                .where((e) => e.status == ProfileEntryStatus.active)
                .toList();
            final calmCount = active
                .where(
                  (e) =>
                      e.section == ProfileEntrySection.earlySign ||
                      e.section == ProfileEntrySection.trigger ||
                      e.section == ProfileEntrySection.whatHelps,
                )
                .length;
            final baselineCount = profileAsync.maybeWhen(
              data: (profile) {
                if (profile == null) return 0;
                return [
                  profile.communicationNotes,
                  profile.sleepBaseline,
                  profile.appetiteBaseline,
                ].where((s) => s != null && s.trim().isNotEmpty).length;
              },
              orElse: () => 0,
            );
            final programCount = programsAsync.maybeWhen(
              data: (programs) => programs.length,
              orElse: () => 0,
            );
            final appSiteCount = appSitesAsync.maybeWhen(
              data: (appSites) => appSites.length,
              orElse: () => 0,
            );
            final lines = <String>[
              if (options.includeCalm)
                _countLine(
                  calmCount,
                  singular: 'Calm-focused profile line',
                  plural: 'Calm-focused profile lines',
                ),
              if (options.includeBaselines)
                _countLine(
                  baselineCount,
                  singular: 'baseline section',
                  plural: 'baseline sections',
                ),
              if (options.includeStructuredProfile)
                _countLine(
                  active.length,
                  singular: 'active structured profile line',
                  plural: 'active structured profile lines',
                ),
              if (options.includePrograms)
                _countLine(
                  programCount,
                  singular: 'program',
                  plural: 'programs',
                ),
              if (options.includeAppSites)
                _countLine(
                  appSiteCount,
                  singular: 'app/site link',
                  plural: 'app/site links',
                ),
              if (options.includeCrisisResources)
                'Support resources and crisis handoff notes',
              if (options.includeAppSites)
                'No passwords, recovery codes, or security answers included',
            ];
            if (lines.isEmpty) {
              return const Text('Turn on at least one section to export.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(line)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _countLine(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural}';
}
