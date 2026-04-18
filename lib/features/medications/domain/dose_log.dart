import 'package:freezed_annotation/freezed_annotation.dart';

part 'dose_log.freezed.dart';

/// What the user did with a scheduled dose.
///
/// Kept deliberately minimal in Phase 1:
///
/// * [taken] — the user confirmed they took it.
/// * [skipped] — the user explicitly chose not to take it ("I'm sick
///   today", "Couldn't find the bottle"). Distinct from "no log at
///   all", which just means upcoming or silently missed.
///
/// Not modelled yet: partial doses, substitutions, "took at a
/// different time than scheduled". Those complications deserve their
/// own design pass rather than being smuggled into the enum now.
enum DoseOutcome {
  taken,
  skipped;

  /// Stable identifier used in the encrypted payload JSON. Rename this
  /// and you break historical dose logs.
  String get wireName => switch (this) {
        DoseOutcome.taken => 'taken',
        DoseOutcome.skipped => 'skipped',
      };

  /// Forward-compatible decode: unknown outcome strings from a newer
  /// payload version fall back to [taken]. Reason: the Today screen
  /// renders a "taken" indicator as the least-wrong default — the user
  /// can always flip it to skipped on the current device.
  static DoseOutcome fromWireName(String? s) {
    for (final v in DoseOutcome.values) {
      if (v.wireName == s) return v;
    }
    return DoseOutcome.taken;
  }
}

/// A persisted record that the user interacted with a specific
/// scheduled dose.
///
/// Identity is `(medicationId, scheduledAt)` — not [id], which is the
/// database row key. Upserts key on the identity pair so a second
/// Taken tap for the same dose replaces the first.
///
/// Timestamps are always UTC. Display conversion to the device's local
/// zone is the view layer's responsibility.
@freezed
abstract class DoseLog with _$DoseLog {
  const factory DoseLog({
    required String id,
    required String personId,
    required String medicationId,

    /// The wall-clock time the dose was due, converted to UTC. Part of
    /// the log's composite identity.
    required DateTime scheduledAt,

    /// When the user tapped Taken / Skipped, in UTC. Used for sort
    /// stability and — Phase 2 — adherence reports.
    required DateTime loggedAt,
    required DoseOutcome outcome,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Optional free-text note, e.g. "took 15 min late, with dinner".
    /// Empty / whitespace-only notes are stored as null by the repo.
    String? note,

    /// Tombstone. Set when the user taps Undo on a previously-logged
    /// dose. Kept rather than hard-deleting so Phase 2 sync is
    /// symmetric with every other table.
    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _DoseLog;
}
