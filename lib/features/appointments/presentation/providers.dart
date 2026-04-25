import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/notifications/appointment_reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/today/domain/today_appointment_item.dart';
import 'package:were_all_in_this_together/features/today/presentation/today_providers.dart';

/// Upcoming (scheduled >= now), non-archived appointments for the
/// currently-active Person, soonest first.
///
/// Watches [activePersonIdProvider] via `.future`, so the list
/// naturally re-resolves when the active Person changes. Mutations
/// local to the appointments domain (create / update / archive /
/// restore) must call [invalidateAppointmentsState] below.
///
/// Returns `[]` when no Person is active — an empty roster is a
/// real UI state the list screen handles with a
/// "Add someone first" prompt.
final upcomingAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Appointment>[];
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.listUpcomingForPerson(personId);
});

/// Past (scheduled < now), non-archived appointments for the active
/// Person, most recent first.
///
/// Rendered below the upcoming list in a collapsible section so
/// historical visits stay visible (for "what did Dr. Chen say last
/// time?") without crowding the live view.
final pastAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Appointment>[];
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.listPastForPerson(personId);
});

/// Archived appointments for the active Person, newest-archived
/// first. Separate from "past" because archived means "cancelled
/// or mis-entered"; past means "it happened, I'm not forgetting it".
final archivedAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final personId = await ref.watch(activePersonIdProvider.future);
  if (personId == null) return const <Appointment>[];
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.listArchivedForPerson(personId);
});

/// Every non-archived appointment scheduled in the device's current
/// *local* calendar day, across every Person the user manages,
/// paired with the owning Person's display name.
///
/// Sourced directly from the repo's `listForPersonInRange` rather
/// than joining the existing upcoming/past providers because:
///
/// * Those two are per-active-Person; Today needs the whole roster
///   (a parent managing a child's 09:00 specialist visit sees it on
///   Today regardless of which Person is "active" in the UI).
/// * Using a single range query keeps the provider a one-shot I/O
///   call and avoids the off-by-one that "concat upcoming + past
///   and filter to today" would invite at the day boundary.
///
/// Reads `todayClockProvider` so widget tests can inject a pinned
/// "now" — one clock source for the whole Today pipeline.
final allTodayAppointmentsProvider =
    FutureProvider<List<OwnedTodayAppointment>>((ref) async {
  final now = ref.watch(todayClockProvider)();
  final people = await ref.watch(peopleListProvider.future);
  final repo = ref.watch(appointmentRepositoryProvider);
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfDay.add(const Duration(days: 1));
  final result = <OwnedTodayAppointment>[];
  for (final person in people) {
    final appts = await repo.listForPersonInRange(
      personId: person.id,
      fromInclusive: startOfDay,
      toExclusive: startOfTomorrow,
    );
    for (final appt in appts) {
      result.add(
        OwnedTodayAppointment(
          appointment: appt,
          personDisplayName: person.displayName,
        ),
      );
    }
  }
  return result;
});

/// Refresh every provider that derives from "which appointments
/// exist".
///
/// Must be called after any create / update / archive / restore so
/// the list screen's three sections all re-fetch.
void invalidateAppointmentsState(WidgetRef ref) {
  ref
    ..invalidate(upcomingAppointmentsProvider)
    ..invalidate(pastAppointmentsProvider)
    ..invalidate(archivedAppointmentsProvider)
    // Invalidating the roster-wide lists keeps one-shot reminder
    // reconciliation and the Today screen feed pointed at fresh data after
    // whatever the user just did (new appointment, time change, archive,
    // restore).
    ..invalidate(allUpcomingAppointmentsProvider)
    ..invalidate(allTodayAppointmentsProvider);
}
