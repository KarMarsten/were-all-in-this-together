import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_event.freezed.dart';

/// The kind of event recorded on a medication's timeline.
///
/// The set is intentionally small — the alternative of a separate
/// enum value per mutable field (doseChanged, scheduleChanged, ...)
/// reads nicely at first but quickly hides the common pattern:
/// "a caregiver edited the medication and a bunch of things changed
/// at once". Instead we emit a single `fieldsChanged` event with a
/// list of field-level [MedicationFieldDiff]s, which renders cleanly
/// on the timeline and keeps the wire shape stable as new fields are
/// added in future schema versions.
enum MedicationEventKind {
  /// The medication was created. No diffs — the initial state is the
  /// current `Medication` itself.
  created,

  /// One or more medically-meaningful fields were changed on an
  /// existing medication. Carries a non-empty `diffs` list.
  fieldsChanged,

  /// The medication was archived (soft-deleted). No diffs.
  archived,

  /// A previously-archived medication was restored. No diffs.
  restored,

  /// A free-text note the user attached to the timeline. Carries no
  /// diffs; all content lives in [MedicationEvent.note]. Used for
  /// side-effect observations, off-label explanations, etc.
  note;

  /// Stable wire name for encrypted-payload round-trips. Decoupling
  /// from Dart identifier stability keeps future renames from being
  /// silently breaking.
  String get wireName => switch (this) {
        MedicationEventKind.created => 'created',
        MedicationEventKind.fieldsChanged => 'fieldsChanged',
        MedicationEventKind.archived => 'archived',
        MedicationEventKind.restored => 'restored',
        MedicationEventKind.note => 'note',
      };

  /// Lookup by wire name. Unknown values from a newer build decode
  /// to [note] so the row still renders — forward compatibility
  /// matters more than precision when the worst case is showing a
  /// user their own history with a slightly-generic description.
  static MedicationEventKind fromWireName(String? s) {
    if (s == null) return MedicationEventKind.note;
    for (final v in MedicationEventKind.values) {
      if (v.wireName == s) return v;
    }
    return MedicationEventKind.note;
  }
}

/// A change to a single field of a medication.
///
/// Values are kept as already-rendered strings so the timeline can
/// display them without decoding every field's domain type. This
/// costs some precision ("10mg" vs `Dose(10, mg)`) but buys us a
/// stable wire shape: adding or evolving a field type (`dose`,
/// `schedule`) won't break historical diffs written under an older
/// build.
///
/// `previous == null && current != null` means the field was set for
/// the first time; `previous != null && current == null` means the
/// field was cleared.
@freezed
abstract class MedicationFieldDiff with _$MedicationFieldDiff {
  const factory MedicationFieldDiff({
    /// Stable wire name of the field, e.g. `dose`, `prescriberId`,
    /// `schedule`. Kept as a string (not an enum) to stay forward-
    /// compatible with future fields — a timeline written under v9
    /// should still render under v8, even if it just says
    /// `someNewField` verbatim.
    required String field,
    String? previous,
    String? current,
  }) = _MedicationFieldDiff;
}

/// A single entry on a medication's history timeline.
///
/// Events are immutable once written in practice — the repository
/// only exposes create / list / archive. Archiving is used to correct
/// a mis-logged event; direct updates are deliberately not supported
/// so an event row's history is trustworthy.
@freezed
abstract class MedicationEvent with _$MedicationEvent {
  const factory MedicationEvent({
    /// Client-generated UUID v4.
    required String id,

    /// Id of the medication this event belongs to.
    required String medicationId,

    /// Owning Person, duplicated from the medication so event
    /// queries don't need a join and AAD scoping matches the other
    /// tables.
    required String personId,

    required MedicationEventKind kind,

    /// When the change took effect in the patient's timeline.
    /// For auto-logged events this equals [createdAt]. Manual
    /// backfill events set this to the historical date the user
    /// reports.
    required DateTime occurredAt,

    /// Row-metadata timestamps (when the event row itself was first
    /// written / last mutated). Separate from [occurredAt] so
    /// backfills keep a clean audit trail of when they were
    /// entered.
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Non-empty only for [MedicationEventKind.fieldsChanged]. Other
    /// kinds keep it `const []`.
    @Default(<MedicationFieldDiff>[])
        List<MedicationFieldDiff> diffs,

    /// Optional free-text annotation. For auto-logged events this is
    /// typically `null`; the user can attach rationale when manually
    /// backfilling or recording a standalone [MedicationEventKind.note].
    String? note,

    DateTime? deletedAt,
    @Default(1) int rowVersion,
    String? lastWriterDeviceId,
    @Default(1) int keyVersion,
  }) = _MedicationEvent;
}
