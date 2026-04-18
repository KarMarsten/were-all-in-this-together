import 'package:drift/drift.dart';

/// Medications table — one row per medication tracked for a Person.
///
/// Like `Persons`, all sensitive fields (name, dose, form, prescriber,
/// notes, start/end dates) live inside the encrypted `payload` blob, under
/// the owning Person's key. Only the metadata needed for indexing,
/// filtering, sync reconciliation, and tombstone replication is stored in
/// the clear:
///
/// * `id` — client-generated UUID v4; stable across devices.
/// * `person_id` — cleartext foreign-key-style reference to the owning
///   Person. We do not declare a SQL foreign key — Phase 2 sync needs to
///   tolerate arrival order (a med row may sync before its Person row).
/// * `created_at` / `updated_at` / `deleted_at` — sort + tombstones.
/// * `row_version`, `last_writer_device_id`, `key_version` — same
///   semantics as on `Persons`.
/// * `payload` — envelope ciphertext (see `EncryptedPayload`).
///
/// Note: this is schema v2. The table was introduced in the medication
/// foundation PR; see `AppDatabase.migration`.
@DataClassName('MedicationRow')
class Medications extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person's id. Not a declared SQL foreign key — see class docs.
  TextColumn get personId => text()();

  /// Epoch milliseconds.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not deleted. Soft-delete only.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter, incremented on every write.
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  /// Identifier of the device that last wrote this row. `null` in Phase 1
  /// (single device); populated in Phase 2.
  TextColumn get lastWriterDeviceId => text().nullable()();

  /// Which key generation decrypted this row's payload.
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
