import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/core/theme/app_theme.dart';
import 'package:were_all_in_this_together/core/theme/theme_mode_preference.dart';
import 'package:were_all_in_this_together/features/medications/notifications/pending_ack_drainer.dart';
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
    try {
      final drainer = ref.read(pendingAckDrainerProvider);
      final written = await drainer.drain();
      if (written > 0 && mounted) {
        // Something was actually ACKed while we were away — the
        // reconciler's dose-log input is now stale, so nudge it.
        ref.invalidate(peopleListProvider);
      }
    } on Object catch (error, st) {
      debugPrint('App startup: pending ACK drain skipped ($error)');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themePreference = ref.watch(themeModePreferenceProvider);
    return MaterialApp.router(
      title: "We're All In This Together",
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themePreference.maybeWhen(
        data: (preference) => preference.themeMode,
        orElse: () => ThemeMode.system,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
