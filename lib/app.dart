import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/core/theme/app_theme.dart';
import 'package:were_all_in_this_together/features/appointments/notifications/appointment_reminder_sync.dart';
import 'package:were_all_in_this_together/features/medications/notifications/pending_ack_drainer.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Drain on first paint as well: when iOS launches the app in response
    // to a notification action tap, the initial frame is effectively a
    // "resume" from the user's perspective.
    WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget on purpose — lifecycle callbacks are sync.
      unawaited(_drain());
    }
  }

  Future<void> _drain() async {
    if (!mounted) return;
    final drainer = ref.read(pendingAckDrainerProvider);
    final written = await drainer.drain();
    if (written > 0 && mounted) {
      // Something was actually ACKed while we were away — the
      // reconciler's dose-log input is now stale, so nudge it.
      ref.invalidate(peopleListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Watch the reminder-sync providers so their `ref.listen` calls
    // stay subscribed for the app's lifetime. They have no visible
    // output — they exist to keep the OS notification queue in step
    // with the medication and appointment lists, respectively.
    ref
      ..watch(reminderSyncProvider)
      ..watch(appointmentReminderSyncProvider);
    return MaterialApp.router(
      title: "We're All In This Together",
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
