import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/medications/data/dose_log_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/medications/domain/scheduled_dose.dart';
import 'package:were_all_in_this_together/features/medications/notifications/reminder_sync.dart';

/// Composite identity of a single scheduled dose: `(medicationId,
/// scheduledAtUtcMs)`. Same shape as the DB's unique-key on
/// `dose_logs`, so callers can zip logs and doses together without
/// translating.
typedef DoseIdentity = ({String medicationId, int scheduledAtUtcMs});

DoseIdentity identityOfDose(ScheduledDose d) => (
      medicationId: d.medicationId,
      scheduledAtUtcMs: d.scheduledAt.toUtc().millisecondsSinceEpoch,
    );

DoseIdentity identityOfLog(DoseLog l) => (
      medicationId: l.medicationId,
      scheduledAtUtcMs: l.scheduledAt.toUtc().millisecondsSinceEpoch,
    );

/// "Now" as a provider so widget tests can override the clock.
///
/// The Today screen is inherently time-sensitive: it needs to know
/// when midnight is and which doses are past/upcoming. Making the
/// clock injectable keeps tests hermetic without reaching for
/// `withClock`.
final todayClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Every scheduled dose in the device's *current local calendar day*.
///
/// Reuses [allActiveMedicationsProvider] as the source so that every
/// medication mutation (create / update / archive / restore) and every
/// Person roster change flows through here automatically — the
/// reminders pipeline and the Today screen are two views of the same
/// underlying "what is the user currently tracking?" list.
final todayScheduledDosesProvider =
    FutureProvider<List<ScheduledDose>>((ref) async {
  final now = ref.watch(todayClockProvider)();
  final owned = await ref.watch(allActiveMedicationsProvider.future);

  final contexts = [
    for (final o in owned)
      DoseSchedulingContext(
        medication: o.medication,
        personDisplayName: o.personDisplayName,
      ),
  ];

  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfDay.add(const Duration(days: 1));
  return expandDoses(
    medications: contexts,
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
});

/// Logs indexed by `(medicationId, scheduledAtUtcMs)` for today's
/// doses only.
///
/// Only queries for medication ids that actually appear in today's
/// schedule expansion — no wasted decrypts for meds that aren't even
/// due today.
final todayDoseLogsProvider =
    FutureProvider<Map<DoseIdentity, DoseLog>>((ref) async {
  final now = ref.watch(todayClockProvider)();
  final doses = await ref.watch(todayScheduledDosesProvider.future);
  if (doses.isEmpty) return const <DoseIdentity, DoseLog>{};

  final repo = ref.watch(doseLogRepositoryProvider);
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfDay.add(const Duration(days: 1));
  final logs = await repo.forMedicationsInRange(
    medicationIds: {for (final d in doses) d.medicationId},
    fromInclusive: startOfDay,
    toExclusive: startOfTomorrow,
  );
  return {for (final l in logs) identityOfLog(l): l};
});

/// Refresh the Today screen after a dose log write.
///
/// We only invalidate the logs provider — the schedule itself didn't
/// change, so recomputing it would just waste work.
void invalidateDoseLogsState(WidgetRef ref) {
  ref.invalidate(todayDoseLogsProvider);
}
