import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/home/ui/home_screen.dart';
import 'package:were_all_in_this_together/features/people/data/person_repository.dart';
import 'package:were_all_in_this_together/features/people/presentation/people_list_screen.dart';
import 'package:were_all_in_this_together/features/people/presentation/person_form_screen.dart';
import 'package:were_all_in_this_together/features/safety_plan/ui/calm_screen.dart';
import 'package:were_all_in_this_together/features/settings/ui/settings_screen.dart';

/// App-wide routes, centralised so deep links and navigation both go through
/// the same source of truth.
abstract class Routes {
  static const home = '/';
  static const calm = '/calm';
  static const settings = '/settings';
  static const people = '/people';
  static const personNew = '/people/new';

  /// The edit route is parameterised on Person id; emit it via [personEdit]
  /// rather than interpolating manually at call sites.
  static const personEditPattern = '/people/:id/edit';

  static String personEdit(String id) => '/people/$id/edit';
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
