import 'package:drift/drift.dart';

/// Persons table — one row per tracked Person.
///
/// The sensitive fields (displayName, pronouns, dob, preferredFramingNotes)
/// are **not** columns here. They live inside the [payload] blob, encrypted
/// under that Person's key. Only the metadata needed for indexing, sync
/// reconciliation, and revocation is stored in the clear:
///
/// * `id` — primary key; stable across devices.
/// * `created_at` / `updated_at` / `deleted_at` — for sort and tombstones.
/// * `row_version` — last-writer-wins merge counter (Phase 2).
/// * `last_writer_device_id` — sync debugging (Phase 2).
/// * `key_version` — lets us rotate keys without rewriting every row
///   atomically; during rotation some rows may carry the old version.
/// * `payload` — envelope ciphertext (see `EncryptedPayload`).
///
/// This is schema v1. Every future migration must preserve the semantic
/// meaning of these columns; changes live in the `MigrationStrategy` in
/// `AppDatabase`.
@DataClassName('PersonRow')
class Persons extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Epoch milliseconds.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not deleted. Soft-delete only — we
  /// never physically delete rows in Phase 1 so sync can reconcile
  /// tombstones in Phase 2.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter, incremented on every write.
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  /// Identifier of the device that last wrote this row. `null` in Phase 1
  /// (single device); populated in Phase 2.
  TextColumn get lastWriterDeviceId => text().nullable()();

  /// Which key generation decrypted this row's payload. Incremented on key
  /// rotation; during rotation some rows may carry the old version until
  /// they're rewritten.
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
