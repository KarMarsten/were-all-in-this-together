import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/apps_sites/data/app_site_repository.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/observations/data/observation_repository.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_entry_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/programs/data/program_repository.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/providers/data/care_provider_repository.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';

/// Global search across the local encrypted domains.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  final Set<_SearchCategory> _enabledCategories = {
    ..._SearchCategory.values,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final resultsAsync = ref.watch(_globalSearchResultsProvider(q));
    final allCategoriesSelected =
        _enabledCategories.length == _SearchCategory.values.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search people, meds, visits, notes...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (s) => setState(() => _query = s),
            ),
          ),
          _SearchFilters(
            enabledCategories: _enabledCategories,
            allCategoriesSelected: allCategoriesSelected,
            onSelectAll: () {
              setState(() {
                _enabledCategories
                  ..clear()
                  ..addAll(_SearchCategory.values);
              });
            },
            onToggle: (category) {
              setState(() {
                if (_enabledCategories.contains(category)) {
                  _enabledCategories.remove(category);
                } else {
                  _enabledCategories.add(category);
                }
              });
            },
          ),
          Expanded(
            child: q.isEmpty
                ? const _SearchPrompt()
                : resultsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (results) {
                      final visible = results
                          .where((r) => _enabledCategories.contains(r.category))
                          .toList();
                      if (visible.isEmpty) {
                        return const Center(child: Text('No matches.'));
                      }
                      return ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _SearchResultTile(
                          result: visible[i],
                          query: q,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Search stays local on this device and reads decrypted records '
              'through the same repositories as the feature screens.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Riverpod's family provider type is intentionally inferred; spelling it out
// would expose generated/internal generic names without improving call sites.
// ignore: specify_nonobvious_property_types
final _globalSearchResultsProvider =
    FutureProvider.family<List<_SearchResult>, String>((ref, query) async {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return const <_SearchResult>[];

      final people = await ref.watch(peopleListProvider.future);
      final results = <_SearchResult>[];

      for (final person in people) {
        if (_matches(q, [person.displayName, person.pronouns])) {
          results.add(
            _SearchResult(
              category: _SearchCategory.people,
              icon: Icons.person_outline,
              title: person.displayName,
              subtitle: 'Person',
              route: Routes.personEdit(person.id),
              rank: _rankingOffset(
                q,
                primary: [person.displayName],
                secondary: [person.pronouns],
              ),
            ),
          );
        }
      }

      final medsRepo = ref.watch(medicationRepositoryProvider);
      final apptRepo = ref.watch(appointmentRepositoryProvider);
      final observationRepo = ref.watch(observationRepositoryProvider);
      final profileEntryRepo = ref.watch(profileEntryRepositoryProvider);
      final providerRepo = ref.watch(careProviderRepositoryProvider);
      final programRepo = ref.watch(programRepositoryProvider);
      final appSiteRepo = ref.watch(appSiteRepositoryProvider);

      for (final person in people) {
        final owner = person.displayName;
        final meds = await medsRepo.listActiveForPerson(person.id);
        results.addAll(_medicationResults(q, owner, meds));

        final upcoming = await apptRepo.listUpcomingForPerson(person.id);
        final past = await apptRepo.listPastForPerson(person.id);
        results.addAll(_appointmentResults(q, owner, [...upcoming, ...past]));

        final observations = await observationRepo.listActiveForPerson(
          person.id,
        );
        results.addAll(_observationResults(q, owner, observations));

        final profileEntries = await profileEntryRepo.listActiveForPerson(
          person.id,
        );
        results.addAll(_profileEntryResults(q, owner, profileEntries));

        final providers = await providerRepo.listActiveForPerson(person.id);
        results.addAll(_providerResults(q, owner, providers));
        final providerNamesById = {
          for (final provider in providers) provider.id: provider.name,
        };

        final programs = await programRepo.listActiveForPerson(person.id);
        results.addAll(
          _programResults(q, owner, programs, providerNamesById),
        );
        final programNamesById = {
          for (final program in programs) program.id: program.name,
        };

        final appSites = await appSiteRepo.listActiveForPerson(person.id);
        results.addAll(
          _appSiteResults(
            q,
            owner,
            appSites,
            providerNamesById,
            programNamesById,
          ),
        );
      }

      results.sort((a, b) {
        final byRank = a.rank.compareTo(b.rank);
        if (byRank != 0) return byRank;
        final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (byTitle != 0) return byTitle;
        return a.subtitle.toLowerCase().compareTo(b.subtitle.toLowerCase());
      });
      return results;
    });

Iterable<_SearchResult> _medicationResults(
  String q,
  String owner,
  List<Medication> meds,
) sync* {
  for (final med in meds) {
    if (!_matches(q, [med.name, med.dose, med.prescriber, med.notes])) continue;
    yield _SearchResult(
      category: _SearchCategory.medications,
      icon: Icons.medication_outlined,
      title: med.name,
      subtitle: _joinParts(['Medication', owner, med.dose]),
      route: Routes.medicationEdit(med.id),
      rank:
          10 +
          _rankingOffset(
            q,
            primary: [med.name],
            secondary: [med.dose, med.prescriber, med.notes],
          ),
    );
  }
}

Iterable<_SearchResult> _appointmentResults(
  String q,
  String owner,
  List<Appointment> appointments,
) sync* {
  for (final appt in appointments) {
    if (!_matches(q, [appt.title, appt.location, appt.notes])) continue;
    yield _SearchResult(
      category: _SearchCategory.appointments,
      icon: Icons.event_outlined,
      title: appt.title,
      subtitle: _joinParts([
        'Appointment',
        owner,
        _formatDate(appt.scheduledAt.toLocal()),
        appt.location,
      ]),
      route: Routes.appointmentEdit(appt.id),
      rank:
          20 +
          _rankingOffset(
            q,
            primary: [appt.title],
            secondary: [appt.location, appt.notes],
          ),
    );
  }
}

Iterable<_SearchResult> _observationResults(
  String q,
  String owner,
  List<Observation> observations,
) sync* {
  for (final note in observations) {
    if (!_matches(q, [note.label, note.notes, ...note.tags])) continue;
    yield _SearchResult(
      category: _SearchCategory.notes,
      icon: Icons.sticky_note_2_outlined,
      title: note.label,
      subtitle: _joinParts([
        'Note',
        owner,
        labelForObservationCategory(note.category),
        _formatDate(note.observedAt.toLocal()),
      ]),
      route: Routes.noteEdit(note.id),
      rank:
          30 +
          _rankingOffset(
            q,
            primary: [note.label],
            secondary: [note.notes, ...note.tags],
          ),
    );
  }
}

Iterable<_SearchResult> _profileEntryResults(
  String q,
  String owner,
  List<ProfileEntry> entries,
) sync* {
  for (final entry in entries) {
    if (!_matches(q, [entry.label, entry.details])) continue;
    yield _SearchResult(
      category: _SearchCategory.profile,
      icon: Icons.psychology_outlined,
      title: entry.label,
      subtitle: _joinParts([
        'Profile',
        owner,
        labelForProfileEntrySection(entry.section),
        labelForProfileEntryStatus(entry.status),
      ]),
      route: Routes.profileEntryEdit(entry.id),
      rank:
          40 +
          _rankingOffset(
            q,
            primary: [entry.label],
            secondary: [entry.details],
          ),
    );
  }
}

Iterable<_SearchResult> _providerResults(
  String q,
  String owner,
  List<CareProvider> providers,
) sync* {
  for (final provider in providers) {
    if (!_matches(q, [
      provider.name,
      provider.specialty,
      provider.role,
      provider.contactName,
      provider.phone,
      provider.email,
      provider.fax,
      provider.address,
      provider.portalLabel,
      provider.portalUrl,
      provider.afterHoursPhone,
      provider.afterHoursInstructions,
      provider.notes,
    ])) {
      continue;
    }
    yield _SearchResult(
      category: _SearchCategory.providers,
      icon: Icons.local_hospital_outlined,
      title: provider.name,
      subtitle: _joinParts([
        'Provider',
        owner,
        _labelForProviderKind(provider.kind),
        provider.specialty,
        provider.role,
        provider.contactName,
      ]),
      route: Routes.careProviderDetail(provider.id),
      rank:
          50 +
          _rankingOffset(
            q,
            primary: [provider.name],
            secondary: [
              provider.specialty,
              provider.role,
              provider.contactName,
              provider.phone,
              provider.email,
              provider.fax,
              provider.address,
              provider.portalLabel,
              provider.portalUrl,
              provider.afterHoursPhone,
              provider.afterHoursInstructions,
              provider.notes,
            ],
          ),
    );
  }
}

Iterable<_SearchResult> _programResults(
  String q,
  String owner,
  List<Program> programs,
  Map<String, String> providerNamesById,
) sync* {
  for (final program in programs) {
    final providerName = providerNamesById[program.providerId];
    if (!_matches(q, [
      program.name,
      providerName,
      program.phone,
      program.contactName,
      program.contactRole,
      program.email,
      program.address,
      program.websiteUrl,
      program.hours,
      program.notes,
    ])) {
      continue;
    }
    yield _SearchResult(
      category: _SearchCategory.programs,
      icon: Icons.school_outlined,
      title: program.name,
      subtitle: _joinParts([
        'Program',
        owner,
        labelForProgramKind(program.kind),
        if (providerName != null) 'Provider: $providerName',
        program.contactName,
      ]),
      route: Routes.programEdit(program.id),
      rank:
          60 +
          _rankingOffset(
            q,
            primary: [program.name],
            secondary: [
              providerName,
              program.phone,
              program.contactName,
              program.contactRole,
              program.email,
              program.address,
              program.websiteUrl,
              program.hours,
              program.notes,
            ],
          ),
    );
  }
}

Iterable<_SearchResult> _appSiteResults(
  String q,
  String owner,
  List<AppSite> sites,
  Map<String, String> providerNamesById,
  Map<String, String> programNamesById,
) sync* {
  for (final site in sites) {
    final providerName = providerNamesById[site.providerId];
    final programName = programNamesById[site.programId];
    if (!_matches(q, [
      site.title,
      site.url,
      labelForAppSiteCategory(site.category),
      providerName,
      programName,
      site.usernameHint,
      site.loginNote,
      site.notes,
    ])) {
      continue;
    }
    yield _SearchResult(
      category: _SearchCategory.appsSites,
      icon: Icons.link_outlined,
      title: site.title,
      subtitle: _joinParts([
        'App/Site',
        owner,
        labelForAppSiteCategory(site.category),
        if (providerName != null) 'Provider: $providerName',
        if (programName != null) 'Program: $programName',
        site.url,
      ]),
      route: Routes.appSiteEdit(site.id),
      rank:
          70 +
          _rankingOffset(
            q,
            primary: [site.title],
            secondary: [
              site.url,
              labelForAppSiteCategory(site.category),
              providerName,
              programName,
              site.usernameHint,
              site.loginNote,
              site.notes,
            ],
          ),
    );
  }
}

bool _matches(String q, Iterable<String?> fields) {
  return fields.any((f) => f != null && f.toLowerCase().contains(q));
}

int _rankingOffset(
  String q, {
  required Iterable<String?> primary,
  Iterable<String?> secondary = const <String?>[],
}) {
  var best = 99;
  for (final field in primary) {
    best = best < _fieldRank(q, field, 0) ? best : _fieldRank(q, field, 0);
  }
  for (final field in secondary) {
    best = best < _fieldRank(q, field, 8) ? best : _fieldRank(q, field, 8);
  }
  return best;
}

int _fieldRank(String q, String? raw, int penalty) {
  final field = raw?.trim().toLowerCase();
  if (field == null || field.isEmpty) return 99;
  if (field == q) return penalty;
  if (field.startsWith(q)) return penalty + 1;
  if (field.split(RegExp(r'\s+')).any((part) => part.startsWith(q))) {
    return penalty + 3;
  }
  if (field.contains(q)) return penalty + 6;
  return 99;
}

String _joinParts(Iterable<String?> parts) {
  return parts
      .where((p) => p != null && p.trim().isNotEmpty)
      .map((p) => p!.trim())
      .join(' · ');
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _labelForProviderKind(CareProviderKind kind) {
  switch (kind) {
    case CareProviderKind.pcp:
      return 'PCP';
    case CareProviderKind.specialist:
      return 'Specialist';
    case CareProviderKind.therapist:
      return 'Therapist';
    case CareProviderKind.dentist:
      return 'Dentist';
    case CareProviderKind.other:
      return 'Other';
  }
}

class _SearchResult {
  const _SearchResult({
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.rank,
  });

  final _SearchCategory category;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int rank;
}

enum _SearchCategory {
  people,
  medications,
  appointments,
  notes,
  profile,
  providers,
  programs,
  appsSites,
}

extension on _SearchCategory {
  String get label {
    switch (this) {
      case _SearchCategory.people:
        return 'People';
      case _SearchCategory.medications:
        return 'Meds';
      case _SearchCategory.appointments:
        return 'Appointments';
      case _SearchCategory.notes:
        return 'Notes';
      case _SearchCategory.profile:
        return 'Profile';
      case _SearchCategory.providers:
        return 'Providers';
      case _SearchCategory.programs:
        return 'Programs';
      case _SearchCategory.appsSites:
        return 'Apps & Sites';
    }
  }

  IconData get icon {
    switch (this) {
      case _SearchCategory.people:
        return Icons.person_outline;
      case _SearchCategory.medications:
        return Icons.medication_outlined;
      case _SearchCategory.appointments:
        return Icons.event_outlined;
      case _SearchCategory.notes:
        return Icons.sticky_note_2_outlined;
      case _SearchCategory.profile:
        return Icons.psychology_outlined;
      case _SearchCategory.providers:
        return Icons.local_hospital_outlined;
      case _SearchCategory.programs:
        return Icons.school_outlined;
      case _SearchCategory.appsSites:
        return Icons.link_outlined;
    }
  }
}

class _SearchFilters extends StatelessWidget {
  const _SearchFilters({
    required this.enabledCategories,
    required this.allCategoriesSelected,
    required this.onSelectAll,
    required this.onToggle,
  });

  final Set<_SearchCategory> enabledCategories;
  final bool allCategoriesSelected;
  final VoidCallback onSelectAll;
  final ValueChanged<_SearchCategory> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: allCategoriesSelected,
              avatar: const Icon(Icons.all_inclusive, size: 18),
              label: const Text('All'),
              onSelected: (_) => onSelectAll(),
            ),
          ),
          for (final category in _SearchCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: enabledCategories.contains(category),
                avatar: Icon(category.icon, size: 18),
                label: Text(category.label),
                onSelected: (_) => onToggle(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.query});

  final _SearchResult result;
  final String query;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(result.icon),
      title: _HighlightedText(text: result.title, query: query),
      subtitle: _HighlightedText(text: result.subtitle, query: query),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(result.route),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) return Text(text);
    final lower = text.toLowerCase();
    final start = lower.indexOf(q.toLowerCase());
    if (start < 0) return Text(text);
    final end = start + q.length;
    final scheme = Theme.of(context).colorScheme;
    final style = DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(
              backgroundColor: scheme.secondaryContainer,
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Type to search people, medications, appointments, notes, profile '
          'entries, providers, programs, apps, and sites.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
