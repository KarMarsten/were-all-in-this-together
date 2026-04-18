import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/core/notifications/notification_service.dart';
import 'package:were_all_in_this_together/core/notifications/scheduled_reminder.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';

/// One medication plus the display name of the Person who owns it.
///
/// The reconciler doesn't read the Person repository directly — it
/// takes this already-resolved pair so the caller controls batching
/// and caching.
@immutable
class OwnedMedication {
  const OwnedMedication({
    required this.medication,
    required this.personDisplayName,
  });

  final Medication medication;
  final String personDisplayName;
}

/// Diff-based sync between the app's medications and the OS's
/// pending notification queue.
///
/// Each dose instance produces a **nag chain**: the initial reminder
/// plus up to `cap` follow-ups spaced `interval` minutes apart. The
/// reconciler:
///
/// 1. Expands active meds into `ScheduledDose`s across the rolling
///    window.
/// 2. Drops any dose already recorded in [DoseLog]s (the caregiver
///    handled it via Today, or an earlier ACK landed).
/// 3. For each remaining dose, emits 1 + cap `ScheduledReminder`s
///    with deterministic ids.
/// 4. Compares desired ids against pending OS ids. Cancels everything
///    that's no longer desired. Schedules everything that's not yet
///    pending.
///
/// Rolling window: defaults to **48 hours** ahead. iOS caps pending
/// notifications at 64 per app; 48h is a comfortable balance for a
/// typical family (a few people × a few meds × default nag cap of 3)
/// without running into that ceiling, and every app open refreshes
/// the window further out.
class ReminderReconciler {
  ReminderReconciler({
    required NotificationService service,
    this.windowDuration = const Duration(hours: 48),
    DateTime Function()? clock,
  })  : _service = service,
        _clock = clock ?? DateTime.now;

  final NotificationService _service;
  final Duration windowDuration;
  final DateTime Function() _clock;

  /// Reconcile against the full medication set. Called on every
  /// change — app start, medication create/update/archive, Person
  /// rename, notification-preference change, and dose-log writes
  /// (so acknowledging a dose on Today cancels its future nags).
  ///
  /// Returns the reminders that ended up scheduled (useful for
  /// logging and for tests).
  Future<List<ScheduledReminder>> reconcile({
    required List<OwnedMedication> meds,
    required NotificationPreferences preferences,
    Map<DoseIdentity, DoseLog>? doseLogsByIdentity,
  }) async {
    final logs = doseLogsByIdentity ?? const <DoseIdentity, DoseLog>{};
    final now = _clock();
    final windowStart = now;
    final windowEnd = now.add(windowDuration);

    final contexts = [
      for (final owned in meds)
        DoseSchedulingContext(
          medication: owned.medication,
          personDisplayName: owned.personDisplayName,
        ),
    ];

    final doses = expandDoses(
      medications: contexts,
      fromInclusive: windowStart,
      toExclusive: windowEnd,
    );

    final owningMeds = <String, OwnedMedication>{
      for (final o in meds) o.medication.id: o,
    };

    final desired = <ScheduledReminder>[];
    for (final dose in doses) {
      final owned = owningMeds[dose.medicationId];
      if (owned == null) continue;

      final identity = (
        medicationId: dose.medicationId,
        scheduledAtUtcMs: dose.scheduledAt.toUtc().millisecondsSinceEpoch,
      );
      if (logs.containsKey(identity)) {
        // Caregiver already logged this dose (via Today, via an ACK
        // that was drained, etc.). No need to remind.
        continue;
      }

      final effective = _effectivePreferences(owned.medication, preferences);
      final chain = _chainFor(
        dose: dose,
        preferences: effective,
        now: now,
      );
      desired.addAll(chain);
    }

    final desiredById = <int, ScheduledReminder>{
      for (final r in desired) r.id: r,
    };

    final pending = await _service.pendingReminderIds();

    for (final id in pending) {
      if (!desiredById.containsKey(id)) {
        await _service.cancelReminder(id);
      }
    }
    for (final entry in desiredById.entries) {
      if (!pending.contains(entry.key)) {
        await _service.scheduleReminder(entry.value);
      }
    }

    return desiredById.values.toList();
  }

  /// Resolve the effective nag interval + cap for [med]. Per-med
  /// overrides win; otherwise the device-wide [preferences] apply.
  /// Out-of-range values are clamped (same bounds the settings UI
  /// enforces) so a future hand-edited encrypted payload can't
  /// talk us into a 0-minute nag loop.
  _EffectivePrefs _effectivePreferences(
    Medication med,
    NotificationPreferences preferences,
  ) {
    final interval = med.nagIntervalMinutesOverride ??
        preferences.nagIntervalMinutes;
    final cap = med.nagCapOverride ?? preferences.nagCap;
    return _EffectivePrefs(
      intervalMinutes: interval.clamp(
        NotificationPreferences.minNagIntervalMinutes,
        NotificationPreferences.maxNagIntervalMinutes,
      ),
      cap: cap.clamp(0, NotificationPreferences.maxNagCap),
    );
  }

  /// Build the nag chain for a single dose.
  ///
  /// * Initial reminder at `dose.scheduledAt`.
  /// * Follow-ups at `scheduledAt + k * interval` for k in 1..cap.
  ///
  /// Any step whose `fireAt` is already in the past relative to
  /// [now] is skipped — iOS can't schedule notifications in the
  /// past, and emitting them would just make the reconciler chase
  /// its tail. (The initial reminder will also be skipped if the
  /// app is first opened after the scheduled moment; the caregiver
  /// will see the pending dose on Today the next time they open
  /// the app.)
  Iterable<ScheduledReminder> _chainFor({
    required ScheduledDose dose,
    required _EffectivePrefs preferences,
    required DateTime now,
  }) sync* {
    final total = 1 + preferences.cap;
    for (var i = 0; i < total; i++) {
      final fireAt = dose.scheduledAt.add(
        Duration(minutes: preferences.intervalMinutes * i),
      );
      if (!fireAt.isAfter(now)) continue;
      yield ScheduledReminder(
        medicationId: dose.medicationId,
        personId: dose.personId,
        medicationName: dose.medicationName,
        personDisplayName: dose.personDisplayName,
        scheduledAt: dose.scheduledAt,
        fireAt: fireAt,
        nagIndex: i,
        totalInChain: total,
        dose: dose.dose,
      );
    }
  }
}

@immutable
class _EffectivePrefs {
  const _EffectivePrefs({
    required this.intervalMinutes,
    required this.cap,
  });

  final int intervalMinutes;
  final int cap;
}
