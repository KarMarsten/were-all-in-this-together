import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'package:were_all_in_this_together/features/medications/presentation/today_screen.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/people_list_screen.dart';
import 'package:were_all_in_this_together/features/people/presentation/person_form_screen.dart';
import 'package:were_all_in_this_together/features/providers/data/care_provider_repository.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_provider_detail_screen.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_provider_form_screen.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart';
import 'package:were_all_in_this_together/features/reports/presentation/adherence_report_screen.dart';
import 'package:were_all_in_this_together/features/safety_plan/ui/calm_screen.dart';
import 'package:were_all_in_this_together/features/settings/ui/notification_settings_screen.dart';
import 'package:were_all_in_this_together/features/settings/ui/settings_screen.dart';

/// App-wide routes, centralised so deep links and navigation both go through
/// the same source of truth.
abstract class Routes {
  static const home = '/';
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

  static const careProviders = '/providers';
  static const careProviderNew = '/providers/new';
  static const careProviderDetailPattern = '/providers/:id';
  static const careProviderEditPattern = '/providers/:id/edit';

  static String careProviderDetail(String id) => '/providers/$id';
  static String careProviderEdit(String id) => '/providers/$id/edit';
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
    final activePersonId =
        await ref.read(activePersonIdProvider.future);
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
    final activePersonId =
        await ref.read(activePersonIdProvider.future);
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
    final activePersonId =
        await ref.read(activePersonIdProvider.future);
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
