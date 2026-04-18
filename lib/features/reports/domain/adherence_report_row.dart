import 'package:flutter/foundation.dart';

import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';

/// One row in the adherence report.
///
/// The caregiver-facing report intentionally exposes only the four
/// columns the user asked for:
///
/// * [scheduledAt] — when the dose was due.
/// * [medicationName] — what should have been taken.
/// * [personName] — who the dose was for.
/// * [ackedBy] — which device / caregiver logged it.
///
/// Everything else (outcome, logged-at timestamp, notes) still ships
/// on the row so the UI can colour-code or drill down without having
/// to re-query; the four-column layout is enforced at the view
/// layer, not here.
///
/// Rows are UTC at this layer. Timezone-aware formatting is the
/// responsibility of the screen and the PDF generator so the report
/// matches the device reading it.
@immutable
class AdherenceReportRow {
  const AdherenceReportRow({
    required this.scheduledAt,
    required this.loggedAt,
    required this.personId,
    required this.personName,
    required this.medicationId,
    required this.medicationName,
    required this.outcome,
    required this.ackedBy,
  });

  final DateTime scheduledAt;
  final DateTime loggedAt;
  final String personId;
  final String personName;
  final String medicationId;
  final String medicationName;
  final DoseOutcome outcome;

  /// Human-readable label of whoever logged the ACK. In Phase 1 this
  /// is always "This device" (single-caregiver, local-only). Phase 2
  /// populates it from the Supabase-side auth profile that wrote the
  /// row.
  final String ackedBy;

  @override
  bool operator ==(Object other) {
    return other is AdherenceReportRow &&
        other.scheduledAt == scheduledAt &&
        other.loggedAt == loggedAt &&
        other.personId == personId &&
        other.personName == personName &&
        other.medicationId == medicationId &&
        other.medicationName == medicationName &&
        other.outcome == outcome &&
        other.ackedBy == ackedBy;
  }

  @override
  int get hashCode => Object.hash(
        scheduledAt,
        loggedAt,
        personId,
        personName,
        medicationId,
        medicationName,
        outcome,
        ackedBy,
      );
}

/// Query spec for an adherence report.
///
/// The service flattens this to `(fromInclusive, toExclusive,
/// personIds)` before hitting the dose-log repository. Keeping the
/// spec as its own value makes the UI → service → PDF path obvious
/// and lets widget tests pin down a query without having to mock a
/// service.
@immutable
class AdherenceReportQuery {
  const AdherenceReportQuery({
    required this.fromInclusive,
    required this.toExclusive,
    this.personId,
  });

  /// Lower bound, inclusive. Expected to be UTC midnight of the
  /// selected calendar day (the UI clamps to that).
  final DateTime fromInclusive;

  /// Upper bound, exclusive. Expected to be UTC midnight of the day
  /// *after* the selected end day.
  final DateTime toExclusive;

  /// When non-null, restrict the report to doses taken by one Person.
  /// `null` means "every Person on this device".
  final String? personId;

  @override
  bool operator ==(Object other) {
    return other is AdherenceReportQuery &&
        other.fromInclusive == fromInclusive &&
        other.toExclusive == toExclusive &&
        other.personId == personId;
  }

  @override
  int get hashCode =>
      Object.hash(fromInclusive, toExclusive, personId);
}
