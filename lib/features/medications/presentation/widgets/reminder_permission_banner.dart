import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/notifications/local_notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';

/// Soft banner on the top of `MedicationsListScreen` that nudges the
/// user to enable reminders — *once*, without blocking the UI.
///
/// Design decisions:
///
/// * Non-modal and dismissable. We never block the app behind a
///   system prompt; users who don't want reminders should still be
///   able to use the medication list as a tracking tool.
/// * Re-shows on every cold start until the user either grants or
///   denies at the OS level — after that we respect their choice.
///   (If denied, the banner becomes an informational one pointing at
///   iOS Settings; for Phase 1 we keep the pointer implicit to avoid
///   a dependency on a settings-deep-link plugin.)
/// * Copy avoids urgency. "Want reminders?" rather than "You'll miss
///   doses unless you enable notifications!" — neurodiversity-
///   affirming framing matters more than conversion.
class ReminderPermissionBanner extends ConsumerStatefulWidget {
  const ReminderPermissionBanner({super.key});

  @override
  ConsumerState<ReminderPermissionBanner> createState() =>
      _ReminderPermissionBannerState();
}

class _ReminderPermissionBannerState
    extends ConsumerState<ReminderPermissionBanner> {
  NotificationPermission? _status;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final service = ref.read(notificationServiceProvider);
    await service.initialize();
    if (!mounted) return;
    final status = await service.permissionStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _request() async {
    final service = ref.read(notificationServiceProvider);
    final result = await service.requestPermission();
    if (result == NotificationPermission.granted) {
      unawaited(reconcileMedicationRemindersOnce(ref));
    }
    if (!mounted) return;
    setState(() => _status = result);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (_status == null) return const SizedBox.shrink();
    if (_status == NotificationPermission.granted) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final isDenied = _status == NotificationPermission.denied;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        elevation: 0,
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.notifications_outlined,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDenied
                          ? 'Reminders are turned off'
                          : 'Want a nudge at dose time?',
                      style: text.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDenied
                          ? 'You can turn notifications back on in your '
                              'device settings whenever you like.'
                          : "We'll only send a notification when a dose is "
                              'scheduled. No noise, no marketing.',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isDenied)
                          FilledButton.tonal(
                            onPressed: _request,
                            child: const Text('Turn on reminders'),
                          ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _dismissed = true),
                          child: Text(isDenied ? 'Got it' : 'Not now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
