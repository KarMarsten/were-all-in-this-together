import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/notifications/local_notification_service.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_repository.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_reconciler.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';

/// Flat list of every active medication on this device, paired with
/// the display name of its owning Person.
///
/// Reminders exist for *every* Person in the roster, not just the
/// active one — a parent managing a child's morning meds needs the
/// alert regardless of which Person is "active" in the UI at the
/// moment the alarm fires.
///
/// Returns an empty list when the roster is empty. A Person whose key
/// is missing (e.g. post-restore drift) is silently skipped so one
/// broken row can't cancel reminders for everyone else.
final allActiveMedicationsProvider =
    FutureProvider<List<OwnedMedication>>((ref) async {
  // Watching peopleListProvider (rather than reading the repo directly)
  // means Person add / rename / soft-delete invalidates this provider
  // for free. The meds repository is read because medication mutations
  // invalidate this provider explicitly from
  // `invalidateMedicationsState`.
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

/// Long-lived provider that reconciles OS reminders with
/// [allActiveMedicationsProvider] whenever the list changes.
///
/// Usage: hold a `ref.watch(reminderSyncProvider)` somewhere that lives
/// as long as the app does (currently the root `App` widget). The
/// provider itself has no public state — its body sets up a listener
/// and returns `void`.
///
/// This does not trigger the iOS permission prompt. The notification
/// service only produces user-visible output after `requestPermission`
/// succeeds, so running reconciliation against an un-permitted service
/// is harmless (it just populates an empty pending queue).
final reminderSyncProvider = Provider<void>((ref) {
  final reconciler = ReminderReconciler(
    service: ref.watch(notificationServiceProvider),
  );

  // `fireImmediately` so startup reconciliation runs without waiting
  // for the first mutation. The listener is automatic: list changes
  // (create/update/archive/restore, Person add/remove, active-person
  // switch that invalidates downstream meds providers) re-trigger it.
  ref.listen(
    allActiveMedicationsProvider,
    (prev, next) {
      next.when(
        data: (meds) {
          // Fire-and-forget: UI doesn't block on reconciliation and a
          // failed schedule should never crash the app.
          unawaited(_safeReconcile(reconciler, meds));
        },
        loading: () {},
        error: (err, st) {
          debugPrint('reminderSync: medications load failed ($err)');
          debugPrintStack(stackTrace: st);
        },
      );
    },
    fireImmediately: true,
  );
});

Future<void> _safeReconcile(
  ReminderReconciler reconciler,
  List<OwnedMedication> meds,
) async {
  try {
    await reconciler.reconcile(meds);
  } on Object catch (error, st) {
    debugPrint('reminderSync: reconcile failed ($error)');
    debugPrintStack(stackTrace: st);
  }
}
