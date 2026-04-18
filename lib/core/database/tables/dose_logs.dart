import 'package:drift/drift.dart';

/// DoseLogs table — append-mostly record of "did the user actually
/// take this dose?" events.
///
/// Identity model: a log entry is keyed on `(medicationId, scheduledAtUtcMs)`
/// — the deterministic pair identifying *which dose* the log refers to.
/// The user tapping Taken twice on the same row should upsert rather
/// than produce duplicate history, so `UNIQUE(medicationId, scheduledAtUtcMs)`
/// is enforced.
///
/// Plaintext columns are the minimum we need to:
///
/// 1. Look up "what's the status of this specific scheduled dose?" in
///    constant time from the Today screen.
/// 2. Query "all logs for these meds between date X and Y" without
///    decrypting every row.
/// 3. Replicate tombstones / row versions in Phase 2 sync.
///
/// Sensitive fields (the exact local-wall-clock `loggedAt`, the
/// outcome, and any free-text note) live inside the encrypted payload
/// under the owning Person's key. The payload's AAD binds to
/// `(doseLogId, personId, medicationId, scheduledAtUtcMs)` so a row
/// cannot be relocated between meds, persons, or time slots.
///
/// Privacy note: `scheduledAtUtcMs` is stored in the clear because the
/// "today" query pattern needs to filter on a date range. This leaks
/// dose timing to anyone with DB access, consistent with the existing
/// posture that `personId` and `medicationId` are already plaintext on
/// the medications table. Content — did they take it, did they skip
/// it, did they note anything — remains encrypted.
///
/// Note: schema v3. Introduced in the Today's-doses PR; see
/// `AppDatabase.migration`.
@DataClassName('DoseLogRow')
class DoseLogs extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person's id. Not a declared SQL foreign key — same
  /// rationale as on `Medications` (Phase 2 arrival order).
  TextColumn get personId => text()();

  /// The medication this log is for. Same rationale as `personId` for
  /// not declaring a SQL FK.
  TextColumn get medicationId => text()();

  /// When this specific scheduled dose was due, in UTC milliseconds.
  /// Part of the log's composite identity together with `medicationId`.
  IntColumn get scheduledAtUtcMs => integer()();

  /// Epoch milliseconds; when the row was first written.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds; updated on every upsert (e.g. user switches
  /// an existing Taken log to Skipped).
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` unless the log was un-done. Using a
  /// tombstone rather than a `DELETE` keeps the Phase 2 sync story
  /// symmetric with every other table.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter, incremented on every
  /// write. Same semantics as on `Medications`.
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

  @override
  List<Set<Column>> get uniqueKeys => [
        // Upsert target: a second Taken tap for the same dose replaces
        // the first rather than creating a phantom duplicate. Composite
        // on (medicationId, scheduledAtUtcMs) because the user can
        // legitimately have many logs per med across different times.
        {medicationId, scheduledAtUtcMs},
      ];
}
