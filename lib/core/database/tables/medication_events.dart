import 'package:drift/drift.dart';

/// Append-only history of changes to a `Medication`.
///
/// One row per regimen event — "started on 10mg", "prescriber changed
/// from Dr. Chen to Dr. Ortiz", "dose raised to 20mg", "paused for two
/// weeks". Events are created:
///
/// * Automatically when `MedicationRepository` creates, updates,
///   archives, or restores a row.
/// * Manually (future PR) when the user backfills past regimen
///   changes for a medication that predates the app.
///
/// Why a separate table rather than a version-log embedded in the
/// medication row? Two reasons:
///
/// 1. **Event semantics**: a regimen change is a first-class thing
///    ("on 2026-03-03 the dose went from 10→20mg, per Dr. Chen").
///    Collapsing it into a version counter loses the narrative.
/// 2. **Sync pressure**: in Phase 2 we want to reconcile event writes
///    independently of the authoritative row — two caregivers can add
///    a backfill event for the same regimen from different devices
///    without competing for the medication row's `rowVersion`.
///
/// Like every other table, all sensitive content (before/after values,
/// free-text notes) lives inside the encrypted `payload` blob. The
/// plaintext columns are what Phase 2 sync needs in the clear:
/// ids, ordering timestamps, soft-delete flag, and version counters.
///
/// Introduced in schema v6; see `AppDatabase.migration`.
@DataClassName('MedicationEventRow')
class MedicationEvents extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// The medication this event belongs to. Not a declared SQL foreign
  /// key — Phase 2 sync needs to tolerate arrival order (an event may
  /// sync before its parent medication row).
  TextColumn get medicationId => text()();

  /// Owning Person's id — duplicated from the parent medication so
  /// listing events for a Person works without a join, and so AAD
  /// binding can scope every ciphertext to its Person like the other
  /// tables.
  TextColumn get personId => text()();

  /// Epoch milliseconds — when the change *took effect* in the
  /// patient's timeline. Equals [createdAt] for auto-logged events
  /// (the change happened at the moment the user saved it), but
  /// manually-entered backfill events set this to the historical
  /// date ("this dose started on 2024-03-01, recorded today").
  IntColumn get occurredAt => integer()();

  /// Epoch milliseconds — when this row was first written.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds — bumped on any payload mutation (future
  /// manual correction flow). For auto-logged events this equals
  /// [createdAt] for the lifetime of the row.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not archived. Archiving an
  /// event preserves history for Phase 2 sync tombstones and lets
  /// users "undo" a mis-logged event without actually losing it.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter, incremented on every
  /// write.
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  /// Identifier of the device that last wrote this row. `null` in
  /// Phase 1 (single device); populated in Phase 2.
  TextColumn get lastWriterDeviceId => text().nullable()();

  /// Which key generation decrypted this row's payload.
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
