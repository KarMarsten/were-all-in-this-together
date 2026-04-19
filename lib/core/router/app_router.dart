import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/presentation/appointment_form_screen.dart';
import 'package:were_all_in_this_together/features/appointments/presentation/appointments_list_screen.dart';
import 'package:were_all_in_this_together/features/apps_sites/data/app_site_repository.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/apps_sites/presentation/app_site_form_screen.dart';
import 'package:were_all_in_this_together/features/apps_sites/presentation/app_sites_list_screen.dart';
import 'package:were_all_in_this_together/features/home/ui/home_screen.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_group_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_event_form_screen.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_form_screen.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_group_form_screen.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_groups_list_screen.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medication_history_screen.dart';
import 'package:were_all_in_this_together/features/medications/presentation/medications_list_screen.dart';
import 'package:were_all_in_this_together/features/milestones/data/milestone_repository.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/milestones/presentation/milestone_form_screen.dart';
import 'package:were_all_in_this_together/features/milestones/presentation/milestones_list_screen.dart';
import 'package:were_all_in_this_together/features/observations/data/observation_repository.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';
import 'package:were_all_in_this_together/features/observations/presentation/observation_form_screen.dart';
import 'package:were_all_in_this_together/features/observations/presentation/observations_list_screen.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/people_list_screen.dart';
import 'package:were_all_in_this_together/features/people/presentation/person_form_screen.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_entry_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/profile_entry_form_screen.dart';
import 'package:were_all_in_this_together/features/profile/presentation/profile_screen.dart';
import 'package:were_all_in_this_together/features/programs/data/program_repository.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/program_form_screen.dart';
import 'package:were_all_in_this_together/features/programs/presentation/programs_list_screen.dart';
import 'package:were_all_in_this_together/features/providers/data/care_provider_repository.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_provider_detail_screen.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_provider_form_screen.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart';
import 'package:were_all_in_this_together/features/reports/presentation/adherence_report_screen.dart';
import 'package:were_all_in_this_together/features/reports/presentation/care_summary_screen.dart';
import 'package:were_all_in_this_together/features/safety_plan/ui/calm_screen.dart';
import 'package:were_all_in_this_together/features/search/presentation/global_search_screen.dart';
import 'package:were_all_in_this_together/features/settings/ui/notification_settings_screen.dart';
import 'package:were_all_in_this_together/features/settings/ui/settings_screen.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_screen.dart';

/// App-wide routes, centralised so deep links and navigation both go through
/// the same source of truth.
abstract class Routes {
  static const home = '/';
  static const search = '/search';
  static const calm = '/calm';
  static const settings = '/settings';
  static const notificationSettings = '/settings/notifications';
  static const people = '/people';
  static const personNew = '/people/new';

  /// The edit route is parameterised on Person id; emit it via [personEdit]
  /// rather than interpolating manually at call sites.
  static const personEditPattern = '/people/:id/edit';

  static String personEdit(String id) => '/people/$id/edit';

  static const medications = '/medications';
  static const medicationNew = '/medications/new';
  static const medicationEditPattern = '/medications/:id/edit';
  static const medicationHistoryPattern = '/medications/:id/history';
  static const medicationHistoryNewPattern = '/medications/:id/history/new';

  static String medicationEdit(String id) => '/medications/$id/edit';
  static String medicationHistory(String id) => '/medications/$id/history';
  static String medicationHistoryNew(String id) =>
      '/medications/$id/history/new';

  static const medicationGroups = '/medications/groups';
  static const medicationGroupNew = '/medications/groups/new';
  static const medicationGroupEditPattern = '/medications/groups/:id/edit';

  static String medicationGroupEdit(String id) =>
      '/medications/groups/$id/edit';

  static const today = '/today';

  static const adherenceReport = '/medications/report';

  static const careSummary = '/care-summary';

  static const programs = '/programs';

  static const programNew = '/programs/new';

  static const programEditPattern = '/programs/:id/edit';

  static String programEdit(String id) => '/programs/$id/edit';

  static const appsSites = '/apps-sites';

  static const appSiteNew = '/apps-sites/new';

  static const appSiteEditPattern = '/apps-sites/:id/edit';

  static String appSiteEdit(String id) => '/apps-sites/$id/edit';

  static const careProviders = '/providers';
  static const careProviderNew = '/providers/new';
  static const careProviderDetailPattern = '/providers/:id';
  static const careProviderEditPattern = '/providers/:id/edit';

  static String careProviderDetail(String id) => '/providers/$id';
  static String careProviderEdit(String id) => '/providers/$id/edit';

  static const appointments = '/appointments';
  static const appointmentNew = '/appointments/new';
  static const appointmentEditPattern = '/appointments/:id/edit';

  static String appointmentEdit(String id) => '/appointments/$id/edit';

  static const milestones = '/milestones';
  static const milestoneNew = '/milestones/new';
  static const milestoneEditPattern = '/milestones/:id/edit';

  static String milestoneEdit(String id) => '/milestones/$id/edit';

  static const notes = '/notes';
  static const noteNew = '/notes/new';
  static const noteEditPattern = '/notes/:id/edit';

  static String noteEdit(String id) => '/notes/$id/edit';

  /// Notes timeline filtered to rows linked to this profile entry id.
  static String notesForProfileEntry(String entryId) =>
      '$notes?profileEntry=${Uri.encodeQueryComponent(entryId)}';

  /// New note with the profile-line link prefilled (query param).
  static String noteNewLinkedToProfileEntry(String entryId) =>
      '$noteNew?profileEntry=${Uri.encodeQueryComponent(entryId)}';

  static const profile = '/profile';

  static const profileEntryNew = '/profile/entries/new';
  static const profileEntryEditPattern = '/profile/entries/:id/edit';

  static String profileEntryEdit(String id) => '/profile/entries/$id/edit';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.search,
        name: 'search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: Routes.calm,
        name: 'calm',
        builder: (context, state) => const CalmScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.notificationSettings,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: Routes.people,
        name: 'people',
        builder: (context, state) => const PeopleListScreen(),
      ),
      GoRoute(
        path: Routes.personNew,
        name: 'person-new',
        builder: (context, state) => const PersonFormScreen(),
      ),
      GoRoute(
        path: Routes.personEditPattern,
        name: 'person-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // Resolve the Person lazily through the repository. We could pass
          // it via `extra` from the list tile, but doing the lookup here
          // means deep links and back-navigation after an app restart also
          // work.
          return _EditPersonLoader(personId: id);
        },
      ),
      GoRoute(
        path: Routes.medications,
        name: 'medications',
        builder: (context, state) => const MedicationsListScreen(),
      ),
      GoRoute(
        path: Routes.medicationNew,
        name: 'medication-new',
        builder: (context, state) => const MedicationFormScreen(),
      ),
      GoRoute(
        path: Routes.medicationEditPattern,
        name: 'medication-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _EditMedicationLoader(medicationId: id);
        },
      ),
      GoRoute(
        path: Routes.medicationHistoryPattern,
        name: 'medication-history',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MedicationHistoryScreen(medicationId: id);
        },
      ),
      GoRoute(
        path: Routes.medicationHistoryNewPattern,
        name: 'medication-history-new',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _MedicationEventFormLoader(medicationId: id);
        },
      ),
      GoRoute(
        path: Routes.medicationGroups,
        name: 'medication-groups',
        builder: (context, state) => const MedicationGroupsListScreen(),
      ),
      GoRoute(
        path: Routes.medicationGroupNew,
        name: 'medication-group-new',
        builder: (context, state) => const MedicationGroupFormScreen(),
      ),
      GoRoute(
        path: Routes.medicationGroupEditPattern,
        name: 'medication-group-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _EditMedicationGroupLoader(groupId: id);
        },
      ),
      GoRoute(
        path: Routes.today,
        name: 'today',
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: Routes.adherenceReport,
        name: 'adherence-report',
        builder: (context, state) => const AdherenceReportScreen(),
      ),
      GoRoute(
        path: Routes.careSummary,
        name: 'care-summary',
        builder: (context, state) => const CareSummaryScreen(),
      ),
      GoRoute(
        path: Routes.programs,
        name: 'programs',
        builder: (context, state) => const ProgramsListScreen(),
      ),
      GoRoute(
        path: Routes.programNew,
        name: 'program-new',
        builder: (context, state) => const ProgramFormScreen(),
      ),
      GoRoute(
        path: Routes.programEditPattern,
        name: 'program-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _ProgramEditLoader(programId: id);
        },
      ),
      GoRoute(
        path: Routes.appsSites,
        name: 'apps-sites',
        builder: (context, state) => const AppSitesListScreen(),
      ),
      GoRoute(
        path: Routes.appSiteNew,
        name: 'app-site-new',
        builder: (context, state) => const AppSiteFormScreen(),
      ),
      GoRoute(
        path: Routes.appSiteEditPattern,
        name: 'app-site-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _AppSiteEditLoader(appSiteId: id);
        },
      ),
      GoRoute(
        path: Routes.careProviders,
        name: 'care-providers',
        builder: (context, state) => const CareProvidersListScreen(),
      ),
      GoRoute(
        path: Routes.careProviderNew,
        name: 'care-provider-new',
        builder: (context, state) => const CareProviderFormScreen(),
      ),
      GoRoute(
        path: Routes.careProviderDetailPattern,
        name: 'care-provider-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _CareProviderDetailLoader(providerId: id);
        },
      ),
      GoRoute(
        path: Routes.careProviderEditPattern,
        name: 'care-provider-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _CareProviderEditLoader(providerId: id);
        },
      ),
      GoRoute(
        path: Routes.appointments,
        name: 'appointments',
        builder: (context, state) => const AppointmentsListScreen(),
      ),
      GoRoute(
        path: Routes.appointmentNew,
        name: 'appointment-new',
        builder: (context, state) => const AppointmentFormScreen(),
      ),
      GoRoute(
        path: Routes.appointmentEditPattern,
        name: 'appointment-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _AppointmentEditLoader(appointmentId: id);
        },
      ),
      GoRoute(
        path: Routes.milestones,
        name: 'milestones',
        builder: (context, state) => const MilestonesListScreen(),
      ),
      GoRoute(
        path: Routes.milestoneNew,
        name: 'milestone-new',
        builder: (context, state) => const MilestoneFormScreen(),
      ),
      GoRoute(
        path: Routes.milestoneEditPattern,
        name: 'milestone-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _MilestoneEditLoader(milestoneId: id);
        },
      ),
      GoRoute(
        path: Routes.notes,
        name: 'notes',
        builder: (context, state) => ObservationsListScreen(
          profileEntryFilterId: state.uri.queryParameters['profileEntry'],
        ),
      ),
      GoRoute(
        path: Routes.noteNew,
        name: 'note-new',
        builder: (context, state) => ObservationFormScreen(
          initialProfileEntryId: state.uri.queryParameters['profileEntry'],
        ),
      ),
      GoRoute(
        path: Routes.noteEditPattern,
        name: 'note-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _NoteEditLoader(noteId: id);
        },
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.profileEntryNew,
        name: 'profile-entry-new',
        builder: (context, state) => const ProfileEntryFormScreen(),
      ),
      GoRoute(
        path: Routes.profileEntryEditPattern,
        name: 'profile-entry-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _ProfileEntryEditLoader(entryId: id);
        },
      ),
    ],
  );
});

/// Internal loader that resolves a Person by id before handing off to the
/// shared form. Kept in this file because it exists purely to make the
/// `/people/:id/edit` route self-contained.
class _EditPersonLoader extends ConsumerWidget {
  const _EditPersonLoader({required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(personRepositoryProvider);
    return FutureBuilder(
      future: repo.findById(personId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final person = snapshot.data;
        if (person == null) {
          // Opens the editor as empty/create for a not-found id would be
          // silently wrong; instead show a not-found state so the user
          // notices. This path is mostly reachable via stale deep links.
          return const _EditNotFound();
        }
        return PersonFormScreen(initialPerson: person);
      },
    );
  }
}

class _EditLoading extends StatelessWidget {
  const _EditLoading();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _EditError extends StatelessWidget {
  const _EditError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    );
  }
}

class _EditNotFound extends StatelessWidget {
  const _EditNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That person isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Same pattern as [_EditPersonLoader] — resolve the medication by id so
/// deep links and app restarts both land on the editor with real data.
/// Looks in both active and archived rows so the Archive → Edit → Restore
/// flow round-trips cleanly.
class _EditMedicationLoader extends ConsumerWidget {
  const _EditMedicationLoader({required this.medicationId});

  final String medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(medicationRepositoryProvider);
    return FutureBuilder<Medication?>(
      future: _resolve(repo, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final med = snapshot.data;
        if (med == null) {
          return const _MedicationEditNotFound();
        }
        return MedicationFormScreen(initialMedication: med);
      },
    );
  }

  /// `findById` only returns active rows, so we fall back to scanning the
  /// archived list if that fails. Archived rows are scoped per Person and
  /// the list screen that links here is always scoped to the active
  /// Person, so that's the right scope to search.
  Future<Medication?> _resolve(
    MedicationRepository repo,
    WidgetRef ref,
  ) async {
    final active = await repo.findById(medicationId);
    if (active != null) return active;
    final activePersonId = await ref.read(activePersonIdProvider.future);
    if (activePersonId == null) return null;
    final archived = await repo.listArchivedForPerson(activePersonId);
    for (final m in archived) {
      if (m.id == medicationId) return m;
    }
    return null;
  }
}

/// Resolver for the `/medications/:id/history/new` route.
///
/// The event form needs the owning Person's id (for AAD scoping on
/// the encrypted payload), but the URL only carries the medication
/// id. We resolve it here so deep links and app restarts both land
/// on a ready-to-type form without the form having to do its own
/// lookup. Uses the same active + archived fallback as
/// `_EditMedicationLoader` so a user who opened history on an
/// archived med can still append notes to its timeline.
class _MedicationEventFormLoader extends ConsumerWidget {
  const _MedicationEventFormLoader({required this.medicationId});

  final String medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(medicationRepositoryProvider);
    return FutureBuilder<Medication?>(
      future: _resolve(repo, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final med = snapshot.data;
        if (med == null) {
          return const _MedicationEditNotFound();
        }
        return MedicationEventFormScreen(
          medicationId: med.id,
          personId: med.personId,
        );
      },
    );
  }

  Future<Medication?> _resolve(
    MedicationRepository repo,
    WidgetRef ref,
  ) async {
    final active = await repo.findById(medicationId);
    if (active != null) return active;
    final activePersonId = await ref.read(activePersonIdProvider.future);
    if (activePersonId == null) return null;
    final archived = await repo.listArchivedForPerson(activePersonId);
    for (final m in archived) {
      if (m.id == medicationId) return m;
    }
    return null;
  }
}

class _MedicationEditNotFound extends StatelessWidget {
  const _MedicationEditNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That medication isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Same shape as [_EditMedicationLoader] — deep-link-safe resolver for
/// the `/medications/groups/:id/edit` route. Falls back to archived
/// rows so Archive → Edit → Restore round-trips cleanly.
class _EditMedicationGroupLoader extends ConsumerWidget {
  const _EditMedicationGroupLoader({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(medicationGroupRepositoryProvider);
    return FutureBuilder<MedicationGroup?>(
      future: _resolve(repo, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final group = snapshot.data;
        if (group == null) {
          return const _MedicationGroupEditNotFound();
        }
        return MedicationGroupFormScreen(initialGroup: group);
      },
    );
  }

  Future<MedicationGroup?> _resolve(
    MedicationGroupRepository repo,
    WidgetRef ref,
  ) async {
    final active = await repo.findById(groupId);
    if (active != null) return active;
    final activePersonId = await ref.read(activePersonIdProvider.future);
    if (activePersonId == null) return null;
    final archived = await repo.listArchivedForPerson(activePersonId);
    for (final g in archived) {
      if (g.id == groupId) return g;
    }
    return null;
  }
}

class _MedicationGroupEditNotFound extends StatelessWidget {
  const _MedicationGroupEditNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That group isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Resolver for the care-provider detail route. `findById` looks at
/// active *and* archived rows, so this route renders archived
/// providers too — important for following a medication's
/// `prescriberId` link even after the provider has been archived.
class _CareProviderDetailLoader extends ConsumerWidget {
  const _CareProviderDetailLoader({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(careProviderRepositoryProvider);
    return FutureBuilder<CareProvider?>(
      future: repo.findById(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final prov = snapshot.data;
        if (prov == null) {
          return const _CareProviderNotFound();
        }
        return CareProviderDetailScreen(provider: prov);
      },
    );
  }
}

class _CareProviderEditLoader extends ConsumerWidget {
  const _CareProviderEditLoader({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(careProviderRepositoryProvider);
    return FutureBuilder<CareProvider?>(
      future: repo.findById(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final prov = snapshot.data;
        if (prov == null) {
          return const _CareProviderNotFound();
        }
        return CareProviderFormScreen(initialProvider: prov);
      },
    );
  }
}

/// Same pattern as [_EditMedicationLoader] — resolve the
/// appointment by id so deep links and app restarts land on the
/// editor with real data. `findById` looks at active and archived
/// rows so Archive → Edit → Restore round-trips cleanly.
class _AppointmentEditLoader extends ConsumerWidget {
  const _AppointmentEditLoader({required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appointmentRepositoryProvider);
    return FutureBuilder<Appointment?>(
      future: repo.findById(appointmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final appt = snapshot.data;
        if (appt == null) {
          return const _AppointmentNotFound();
        }
        return AppointmentFormScreen(initialAppointment: appt);
      },
    );
  }
}

class _AppointmentNotFound extends StatelessWidget {
  const _AppointmentNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That appointment isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CareProviderNotFound extends StatelessWidget {
  const _CareProviderNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That provider isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Same pattern as [_AppointmentEditLoader] — resolve the milestone
/// by id so deep links and app restarts land on the editor with real
/// data. `findById` looks at active and archived rows so Archive →
/// Edit → Restore round-trips cleanly.
class _MilestoneEditLoader extends ConsumerWidget {
  const _MilestoneEditLoader({required this.milestoneId});

  final String milestoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(milestoneRepositoryProvider);
    return FutureBuilder<Milestone?>(
      future: repo.findById(milestoneId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final milestone = snapshot.data;
        if (milestone == null) {
          return const _MilestoneNotFound();
        }
        return MilestoneFormScreen(initialMilestone: milestone);
      },
    );
  }
}

class _MilestoneNotFound extends StatelessWidget {
  const _MilestoneNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That milestone isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Resolve a note by id for `/notes/:id/edit`. Includes archived rows.
class _NoteEditLoader extends ConsumerWidget {
  const _NoteEditLoader({required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(observationRepositoryProvider);
    return FutureBuilder<Observation?>(
      future: repo.findById(noteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final note = snapshot.data;
        if (note == null) {
          return const _NoteNotFound();
        }
        return ObservationFormScreen(initialObservation: note);
      },
    );
  }
}

class _NoteNotFound extends StatelessWidget {
  const _NoteNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That note isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Resolve a profile entry by id for `/profile/entries/:id/edit`.
/// Includes archived rows so restore flows work.
class _ProfileEntryEditLoader extends ConsumerWidget {
  const _ProfileEntryEditLoader({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(profileEntryRepositoryProvider);
    return FutureBuilder<ProfileEntry?>(
      future: repo.findById(entryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final entry = snapshot.data;
        if (entry == null) {
          return const _ProfileEntryNotFound();
        }
        return ProfileEntryFormScreen(initialEntry: entry);
      },
    );
  }
}

class _ProfileEntryNotFound extends StatelessWidget {
  const _ProfileEntryNotFound();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That profile entry isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ProgramEditLoader extends ConsumerWidget {
  const _ProgramEditLoader({required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(programRepositoryProvider);
    return FutureBuilder<Program?>(
      future: repo.findById(programId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final program = snapshot.data;
        if (program == null) {
          return const _ProgramNotFound();
        }
        return ProgramFormScreen(initialProgram: program);
      },
    );
  }
}

class _ProgramNotFound extends StatelessWidget {
  const _ProgramNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That program isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _AppSiteEditLoader extends ConsumerWidget {
  const _AppSiteEditLoader({required this.appSiteId});

  final String appSiteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appSiteRepositoryProvider);
    return FutureBuilder<AppSite?>(
      future: repo.findById(appSiteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EditLoading();
        }
        if (snapshot.hasError) {
          return _EditError(message: snapshot.error.toString());
        }
        final site = snapshot.data;
        if (site == null) {
          return const _AppSiteNotFound();
        }
        return AppSiteFormScreen(initialSite: site);
      },
    );
  }
}

class _AppSiteNotFound extends StatelessWidget {
  const _AppSiteNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "That saved link isn't in this app anymore.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
