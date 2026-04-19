import 'package:freezed_annotation/freezed_annotation.dart';

part 'milestone.freezed.dart';

/// Categories we pre-colour and pre-group on the list screen.
///
/// Kept small on purpose — a long enum becomes a find-my-category
/// puzzle the user has to solve every time they log a new
/// milestone. The goal is "place this roughly" in one tap, not
/// "classify this precisely". A `notes` field on the milestone
/// itself absorbs any nuance the enum can't.
///
/// Order of the cases is the persisted order — never reorder, only
/// append. See `milestones.kind` column doc for the forward-compat
/// policy.
enum MilestoneKind {
  /// Formal diagnoses, screenings, assessments — ASD, ADHD,
  /// allergies, dyslexia, etc.
  diagnosis,

  /// Vaccines, immunisations, boosters. The canonical "when was
  /// the last flu shot?" question lives here.
  vaccine,

  /// Developmental firsts — first words, first steps, bike without
  /// training wheels, tying shoelaces, reading a chapter book.
  development,

  /// Non-diagnosis health events — surgeries, ER visits,
  /// fractures, notable illnesses.
  health,

  /// Life events — moved house, started school, got a sibling,
  /// adopted the dog, big trip.
  life,

  /// Anything that doesn't fit the above. Preferable to forcing a
  /// bad category onto a real event.
  other,
}

/// How precisely the user knows *when* a milestone happened.
///
/// Ordered so comparisons make sense: `year < month < day < exact`.
/// Storage lays the canonical instant (start-of-period) in
/// `occurredAt` and uses this to drive rendering + range
/// filtering. A week-precise tier was considered and cut — the UI
/// gain is marginal over day, and the month/year tiers already
/// cover "around this time".
///
/// Append-only enum; see `milestones.precision` column doc.
enum MilestonePrecision {
  /// "2019" — `occurredAt` is `DateTime.utc(2019, 1, 1)`.
  year,

  /// "March 2024" — `occurredAt` is the first of that month UTC.
  month,

  /// "Mar 14, 2024" — `occurredAt` is start-of-day UTC.
  day,

  /// "Mar 14, 2024 at 09:00" — `occurredAt` is the exact UTC
  /// instant.
  exact,
}

/// A single dated event in a Person's life history.
///
/// Immutable, created / mutated only through `MilestoneRepository`.
/// Sensitive fields (`title`, `notes`) are encrypted at rest;
/// structural fields (`occurredAt`, `precision`, `kind`,
/// `providerId`) are plaintext on the row so list screens and
/// future search can operate without decrypting every row.
@freezed
abstract class Milestone with _$Milestone {
  const factory Milestone({
    /// Client-generated UUID v4.
    required String id,

    /// Owning Person's id. Never mutated — moving a milestone
    /// between People requires a new row so AAD / key binding
    /// stays honest.
    required String personId,

    /// Which of the six pre-defined categories this milestone
    /// falls into. Drives icon, tint, and list grouping.
    required MilestoneKind kind,

    /// Free-form title. Required — "Flu shot", "Diagnosed with
    /// ASD", "First words", "Moved to Amsterdam".
    required String title,

    /// Canonical UTC instant the milestone is dated at. For
    /// non-exact precision, this is the **start** of the period
    /// (year → Jan 1, month → the 1st, day → 00:00 UTC). Keeping
    /// the sort key as a single instant means chronological lists
    /// work without a special-case comparator.
    required DateTime occurredAt,

    /// How precisely the user knows when this happened. Controls
    /// UI rendering and fuzzy-date rules.
    required MilestonePrecision precision,

    /// Metadata propagated from the DB row.
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Optional link to a `CareProvider`. Same soft-reference
    /// pattern as `Appointment.providerId` and
    /// `Medication.prescriberId` — archived providers still
    /// resolve so historical attribution survives retirement.
    String? providerId,

    /// Free-form notes. Where the story goes: "Second dose of
    /// two", "Dr. Chen was very kind", "walked holding the couch
    /// first, confident after two weeks".
    String? notes,

    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _Milestone;
}

/// Render a milestone's `occurredAt` at the appropriate granularity.
///
/// Locale-agnostic on purpose (no `intl` yet in this codebase);
/// year / "Mar 2024" / "Mar 14, 2024" / "Mar 14, 2024 at 09:00"
/// all work regardless of locale and render predictably in every
/// test.
///
/// Rendering uses the **UTC** field values for `year` / `month` /
/// `day` precision because the canonical `occurredAt` was stored as
/// start-of-period UTC; converting to local first would drift the
/// label across timezones (a "2019-01-01 UTC" milestone in
/// New Zealand would otherwise label as "2019", but in the US as
/// "2018"). For `exact` we convert to local — users expect exact
/// times to reflect their current wall clock.
String formatMilestoneDate(Milestone m) {
  final dUtc = m.occurredAt.toUtc();
  switch (m.precision) {
    case MilestonePrecision.year:
      return '${dUtc.year}';
    case MilestonePrecision.month:
      return '${_monthName(dUtc.month)} ${dUtc.year}';
    case MilestonePrecision.day:
      return '${_monthShort(dUtc.month)} ${dUtc.day}, ${dUtc.year}';
    case MilestonePrecision.exact:
      final local = m.occurredAt.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '${_monthShort(local.month)} ${local.day}, ${local.year}'
          ' at $hh:$mm';
  }
}

/// Snap an arbitrary instant to the start-of-period for
/// [precision], in UTC. The repository applies this on every write
/// so `occurredAt` is always canonical; helpers and tests can
/// reuse it to stay in sync.
DateTime canonicaliseOccurredAt(DateTime input, MilestonePrecision precision) {
  final utc = input.toUtc();
  switch (precision) {
    case MilestonePrecision.year:
      return DateTime.utc(utc.year);
    case MilestonePrecision.month:
      return DateTime.utc(utc.year, utc.month);
    case MilestonePrecision.day:
      return DateTime.utc(utc.year, utc.month, utc.day);
    case MilestonePrecision.exact:
      return utc;
  }
}

String _monthName(int m) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][m - 1];

String _monthShort(int m) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][m - 1];
