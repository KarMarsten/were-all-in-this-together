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
  ConsumerState<GlobalSearchScreen> createState() =>
      _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final resultsAsync = ref.watch(_globalSearchResultsProvider(q));

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
          Expanded(
            child: q.isEmpty
                ? const _SearchPrompt()
                : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (results) {
                if (results.isEmpty) {
                  return const Center(child: Text('No matches.'));
                }
                return ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _SearchResultTile(
                    result: results[i],
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
          icon: Icons.person_outline,
          title: person.displayName,
          subtitle: 'Person',
          route: Routes.personEdit(person.id),
          rank: 0,
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

    final observations = await observationRepo.listActiveForPerson(person.id);
    results.addAll(_observationResults(q, owner, observations));

    final profileEntries =
        await profileEntryRepo.listActiveForPerson(person.id);
    results.addAll(_profileEntryResults(q, owner, profileEntries));

    final providers = await providerRepo.listActiveForPerson(person.id);
    results.addAll(_providerResults(q, owner, providers));

    final programs = await programRepo.listActiveForPerson(person.id);
    results.addAll(_programResults(q, owner, programs));

    final appSites = await appSiteRepo.listActiveForPerson(person.id);
    results.addAll(_appSiteResults(q, owner, appSites));
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
      icon: Icons.medication_outlined,
      title: med.name,
      subtitle: _joinParts(['Medication', owner, med.dose]),
      route: Routes.medicationEdit(med.id),
      rank: 10,
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
      icon: Icons.event_outlined,
      title: appt.title,
      subtitle: _joinParts([
        'Appointment',
        owner,
        _formatDate(appt.scheduledAt.toLocal()),
        appt.location,
      ]),
      route: Routes.appointmentEdit(appt.id),
      rank: 20,
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
      icon: Icons.sticky_note_2_outlined,
      title: note.label,
      subtitle: _joinParts([
        'Note',
        owner,
        labelForObservationCategory(note.category),
        _formatDate(note.observedAt.toLocal()),
      ]),
      route: Routes.noteEdit(note.id),
      rank: 30,
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
      icon: Icons.psychology_outlined,
      title: entry.label,
      subtitle: _joinParts([
        'Profile',
        owner,
        labelForProfileEntrySection(entry.section),
        labelForProfileEntryStatus(entry.status),
      ]),
      route: Routes.profileEntryEdit(entry.id),
      rank: 40,
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
      provider.phone,
      provider.address,
      provider.portalUrl,
      provider.notes,
    ])) {
      continue;
    }
    yield _SearchResult(
      icon: Icons.local_hospital_outlined,
      title: provider.name,
      subtitle: _joinParts([
        'Provider',
        owner,
        _labelForProviderKind(provider.kind),
        provider.specialty,
      ]),
      route: Routes.careProviderDetail(provider.id),
      rank: 50,
    );
  }
}

Iterable<_SearchResult> _programResults(
  String q,
  String owner,
  List<Program> programs,
) sync* {
  for (final program in programs) {
    if (!_matches(q, [
      program.name,
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
      icon: Icons.school_outlined,
      title: program.name,
      subtitle: _joinParts([
        'Program',
        owner,
        labelForProgramKind(program.kind),
        program.contactName,
      ]),
      route: Routes.programEdit(program.id),
      rank: 60,
    );
  }
}

Iterable<_SearchResult> _appSiteResults(
  String q,
  String owner,
  List<AppSite> sites,
) sync* {
  for (final site in sites) {
    if (!_matches(q, [
      site.title,
      site.url,
      labelForAppSiteCategory(site.category),
      site.usernameHint,
      site.loginNote,
      site.notes,
    ])) {
      continue;
    }
    yield _SearchResult(
      icon: Icons.link_outlined,
      title: site.title,
      subtitle: _joinParts([
        'App/Site',
        owner,
        labelForAppSiteCategory(site.category),
        site.url,
      ]),
      route: Routes.appSiteEdit(site.id),
      rank: 70,
    );
  }
}

bool _matches(String q, Iterable<String?> fields) {
  return fields.any((f) => f != null && f.toLowerCase().contains(q));
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.rank,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int rank;
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result});

  final _SearchResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(result.icon),
      title: Text(result.title),
      subtitle: Text(result.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(result.route),
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
