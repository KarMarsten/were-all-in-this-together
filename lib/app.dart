import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/core/theme/app_theme.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Watch the reminder-sync provider so its `ref.listen` stays
    // subscribed for the app's lifetime. The provider itself has no
    // visible output — it exists to keep the OS notification queue in
    // step with the medication list.
    ref.watch(reminderSyncProvider);
    return MaterialApp.router(
      title: "We're All In This Together",
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
