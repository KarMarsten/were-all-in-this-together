import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';
import 'package:were_all_in_this_together/features/medications/domain/today_item.dart';

/// One Today-screen row representing a scheduled appointment.
///
/// Implements [TodayItem] so it slots straight into the existing
/// time-ordered list the screen iterates — the merge step in
/// `today_providers.dart` sorts solo doses, group bundles, and
/// appointments together on [TodayItem.scheduledAt]. Keeping the
/// row shape uniform is what lets a 09:00 specialist visit render
/// between the 08:00 and 10:00 doses without any special casing on
/// the layout side.
@immutable
class TodayAppointmentItem extends TodayItem {
  const TodayAppointmentItem({
    required this.appointment,
    required this.personDisplayName,
  });

  final Appointment appointment;

  @override
  final String personDisplayName;

  @override
  DateTime get scheduledAt => appointment.scheduledAt;

  @override
  String get personId => appointment.personId;
}

/// Filter an already-range-queried appointment list down to the
/// rows the Today screen should render, and wrap each in a
/// [TodayAppointmentItem].
///
/// Input expectations:
///
/// * [appointments] are already scoped to a [fromInclusive,
///   toExclusive) UTC window — callers compute that window from
///   the device's current local calendar day to match how
///   `expandTodayItems` handles med schedules.
/// * Archived rows (`deletedAt != null`) are dropped defensively,
///   even though the repo query that feeds this helper already
///   excludes them, because the domain function is reused by
///   future callers (e.g. a dashboard widget) that may pass a
///   less-strict source.
///
/// The output is sorted ascending on `scheduledAt` so the merge
/// step in the provider can rely on each expansion being
/// pre-sorted.
List<TodayAppointmentItem> expandTodayAppointmentItems({
  required Iterable<OwnedTodayAppointment> appointments,
  required DateTime fromInclusive,
  required DateTime toExclusive,
}) {
  final fromUtc = fromInclusive.toUtc();
  final toUtc = toExclusive.toUtc();
  final out = <TodayAppointmentItem>[];
  for (final owned in appointments) {
    final appt = owned.appointment;
    if (appt.deletedAt != null) continue;
    final scheduledUtc = appt.scheduledAt.toUtc();
    if (scheduledUtc.isBefore(fromUtc)) continue;
    if (!scheduledUtc.isBefore(toUtc)) continue;
    out.add(
      TodayAppointmentItem(
        appointment: appt,
        personDisplayName: owned.personDisplayName,
      ),
    );
  }
  out.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return out;
}

/// One appointment paired with its owning Person's display name —
/// mirror of `OwnedMedication` / `OwnedAppointment` in the
/// reminders layer. Lives here (rather than being reused from the
/// reminders module) so the domain helper has no dependency on the
/// notifications stack.
@immutable
class OwnedTodayAppointment {
  const OwnedTodayAppointment({
    required this.appointment,
    required this.personDisplayName,
  });

  final Appointment appointment;
  final String personDisplayName;
}
