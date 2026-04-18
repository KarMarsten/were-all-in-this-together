import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/features/home/ui/home_screen.dart';
import 'package:were_all_in_this_together/features/safety_plan/ui/calm_screen.dart';
import 'package:were_all_in_this_together/features/settings/ui/settings_screen.dart';

/// App-wide routes, centralised so deep links and navigation both go through
/// the same source of truth.
abstract class Routes {
  static const home = '/';
  static const calm = '/calm';
  static const settings = '/settings';
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
    ],
  );
});
