import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/notifications/local_notification_service.dart';
import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/data/notification_preferences_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_reconciler.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

/// Flat list of every active medication on this device, paired with
/// the display name of its owning Person.
///
/// Reminders exist for every Person in the roster, not just the
/// active one — a parent managing a child's morning meds needs the
/// alert regardless of which Person is "active" in the UI at the
/// moment the alarm fires.
final allActiveMedicationsProvider =
    FutureProvider<List<OwnedMedication>>((ref) async {
  final people = await ref.watch(peopleListProvider.future);
  final medsRepo = ref.watch(medicationRepositoryProvider);
  final result = <OwnedMedication>[];
  for (final person in people) {
    final meds = await medsRepo.listActiveForPerson(person.id);
    for (final med in meds) {
      result.add(
        OwnedMedication(medication: med, personDisplayName: person.displayName),
      );
    }
  }
  return result;
});

/// Window duration the reconciler schedules ahead of `now`. Exposed
/// as a provider so tests and a future "advanced settings" screen
/// can override it without reaching into the reconciler.
///
/// iOS caps pending notifications at 64 per app. 48 hours balances
/// "scheduled far enough that a user who skips a day still gets
/// tomorrow's alerts" against "doesn't blow through the ceiling
/// for families with many meds".
final reminderWindowProvider = Provider<Duration>((ref) {
  return const Duration(hours: 48);
});

/// Dose logs for every active medication within the reconciler
/// window. The reconciler uses this to skip doses the caregiver has
/// already acknowledged via Today or via a drained ACK.
///
/// Kept narrow to the window on purpose — loading every dose log
/// ever written would be wasteful and would churn this provider on
/// unrelated historical edits.
final _reconcilerDoseLogsProvider =
    FutureProvider<Map<DoseIdentity, DoseLog>>((ref) async {
  final meds = await ref.watch(allActiveMedicationsProvider.future);
  if (meds.isEmpty) return const <DoseIdentity, DoseLog>{};

  final window = ref.watch(reminderWindowProvider);
  final now = DateTime.now();
  final repo = ref.watch(doseLogRepositoryProvider);
  final logs = await repo.forMedicationsInRange(
    medicationIds: {for (final m in meds) m.medication.id},
    fromInclusive: now.subtract(const Duration(hours: 1)),
    toExclusive: now.add(window),
  );
  return {for (final l in logs) identityOfLog(l): l};
});

/// Long-lived provider that reconciles OS reminders whenever any of
/// its inputs change:
///
/// * The medication list (add / rename / archive / restore).
/// * The Person list (new roster member, rename).
/// * Notification preferences (nag interval, nag cap).
/// * Dose logs in the window (an ACK drained, a Today-screen
///   "Taken", etc.).
///
/// Hold a `ref.watch(reminderSyncProvider)` at the app root for the
/// subscription to stay alive.
final reminderSyncProvider = Provider<void>((ref) {
  final reconciler = ReminderReconciler(
    service: ref.watch(notificationServiceProvider),
    windowDuration: ref.watch(reminderWindowProvider),
  );

  // Watch everything that should trigger reconciliation. `listen`
  // on each input so any combination of readiness resolves as soon
  // as the LAST provider's data arrives — otherwise we'd reconcile
  // too eagerly with a stale meds list but fresh prefs (or vice
  // versa) and flicker the OS queue.
  ref
    ..listen<AsyncValue<List<OwnedMedication>>>(
      allActiveMedicationsProvider,
      (_, _) => _maybeReconcile(ref, reconciler),
      fireImmediately: true,
    )
    ..listen(
      notificationPreferencesProvider,
      (_, _) => _maybeReconcile(ref, reconciler),
    )
    ..listen(
      _reconcilerDoseLogsProvider,
      (_, _) => _maybeReconcile(ref, reconciler),
    );
});

void _maybeReconcile(Ref ref, ReminderReconciler reconciler) {
  final meds = ref.read(allActiveMedicationsProvider);
  final prefs = ref.read(notificationPreferencesProvider);
  final logs = ref.read(_reconcilerDoseLogsProvider);

  if (meds is! AsyncData<List<OwnedMedication>>) return;
  if (prefs is! AsyncData<NotificationPreferences>) return;
  // dose logs are optional — if they haven't loaded yet we reconcile
  // without them, because the worst case is "one extra nag fires for
  // a dose the user already logged" and that's preferable to
  // blocking reconciliation behind an async query.
  final logsData = logs is AsyncData<Map<DoseIdentity, DoseLog>>
      ? logs.value
      : null;

  unawaited(
    _safeReconcile(
      reconciler: reconciler,
      meds: meds.value,
      preferences: prefs.value,
      logs: logsData,
    ),
  );
}

Future<void> _safeReconcile({
  required ReminderReconciler reconciler,
  required List<OwnedMedication> meds,
  required NotificationPreferences preferences,
  required Map<DoseIdentity, DoseLog>? logs,
}) async {
  try {
    await reconciler.reconcile(
      meds: meds,
      preferences: preferences,
      doseLogsByIdentity: logs,
    );
  } on Object catch (error, st) {
    debugPrint('reminderSync: reconcile failed ($error)');
    debugPrintStack(stackTrace: st);
  }
}
