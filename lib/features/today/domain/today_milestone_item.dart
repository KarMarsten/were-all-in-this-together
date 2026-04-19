import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';
import 'package:were_all_in_this_together/features/today/domain/today_item.dart';

/// One Today-screen row for a milestone whose calendar day matches
/// today — an "on this day" anniversary nudge alongside doses and
/// appointments.
///
/// Implements `TodayItem` so the merged feed can sort on
/// `scheduledAt`. We anchor at **local midnight** for the current
/// calendar day so these rows interleave with morning doses rather
/// than pretending to be a timed event.
@immutable
class TodayMilestoneItem extends TodayItem {
  const TodayMilestoneItem({
    required this.milestone,
    required this.personDisplayName,
    required this.scheduledAt,
  });

  final Milestone milestone;

  @override
  final String personDisplayName;

  @override
  final DateTime scheduledAt;

  @override
  String get personId => milestone.personId;
}

/// One milestone paired with its owning Person's display name —
/// same roster-wide pairing pattern as appointments on Today.
@immutable
class OwnedTodayMilestone {
  const OwnedTodayMilestone({
    required this.milestone,
    required this.personDisplayName,
  });

  final Milestone milestone;
  final String personDisplayName;
}

/// Whether [milestone] should surface on Today's feed for the
/// device's current local calendar day.
///
/// Only [MilestonePrecision.day] and [MilestonePrecision.exact] rows
/// participate — year- and month-only memories don't map cleanly to
/// a single wall day without surprising the user.
///
/// [now] is typically `DateTime.now` (or a test override); only its
/// local Y/M/D components matter.
///
/// Future-dated milestones (same month/day but a later calendar year
/// than today) are excluded so "starts next April" doesn't appear
/// prematurely.
bool milestoneAnniversaryMatchesToday({
  required Milestone milestone,
  required DateTime now,
}) {
  if (milestone.deletedAt != null) return false;
  if (milestone.precision != MilestonePrecision.day &&
      milestone.precision != MilestonePrecision.exact) {
    return false;
  }
  final todayLocal = DateTime(now.year, now.month, now.day);

  if (milestone.precision == MilestonePrecision.day) {
    // `formatMilestoneDate` uses UTC y/m/d for this tier — stay in
    // that frame so a stored `DateTime.utc(2020, 4, 18)` doesn't
    // vanish on negative-offset devices after `toLocal()`.
    final u = milestone.occurredAt.toUtc();
    if (u.month != todayLocal.month || u.day != todayLocal.day) {
      return false;
    }
    if (u.year > todayLocal.year) return false;
    return true;
  }

  final anchor = milestone.occurredAt.toLocal();
  if (anchor.month != todayLocal.month || anchor.day != todayLocal.day) {
    return false;
  }
  final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
  if (anchorDay.isAfter(todayLocal)) return false;
  return true;
}

/// Human subtitle like "6 years ago" or "This year" for a milestone
/// whose calendar day matches [today] (local midnight).
String milestoneAnniversarySubtitle({
  required Milestone milestone,
  required DateTime today,
}) {
  final eventYear = milestone.precision == MilestonePrecision.day
      ? milestone.occurredAt.toUtc().year
      : milestone.occurredAt.toLocal().year;
  final years = today.year - eventYear;
  if (years <= 0) return 'This year';
  if (years == 1) return '1 year ago';
  return '$years years ago';
}

/// Filter [milestones] down to anniversary rows for [now]'s local
/// calendar day, wrap each in `TodayMilestoneItem`, and sort.
///
/// The `scheduledAt` field on every item is local midnight for the current day
/// (converted to UTC) so the merged list can compare against dose /
/// appointment instants consistently.
List<TodayMilestoneItem> expandTodayMilestoneItems({
  required Iterable<OwnedTodayMilestone> milestones,
  required DateTime now,
}) {
  final todayLocal = DateTime(now.year, now.month, now.day);
  final scheduledAt = todayLocal.toUtc();
  final out = <TodayMilestoneItem>[];
  for (final owned in milestones) {
    final m = owned.milestone;
    if (!milestoneAnniversaryMatchesToday(milestone: m, now: now)) {
      continue;
    }
    out.add(
      TodayMilestoneItem(
        milestone: m,
        personDisplayName: owned.personDisplayName,
        scheduledAt: scheduledAt,
      ),
    );
  }
  out.sort((a, b) {
    final byTime = a.scheduledAt.compareTo(b.scheduledAt);
    if (byTime != 0) return byTime;
    return a.milestone.occurredAt.compareTo(b.milestone.occurredAt);
  });
  return out;
}
