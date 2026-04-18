import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/features/appointments/data/appointment_repository.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/appointments/notifications/appointment_reminder_sync.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';

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
    // Invalidating the roster-wide list re-triggers reminder
    // reconciliation via `appointmentReminderSyncProvider`'s
    // listener — the OS notification queue is treated as derived
    // state and must stay in lockstep with whatever the user just
    // did (new appointment, time change, archive, restore).
    ..invalidate(allUpcomingAppointmentsProvider);
}
