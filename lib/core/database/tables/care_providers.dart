import 'package:drift/drift.dart';

/// Care providers table — one row per clinical or care-adjacent contact
/// (PCP, specialist, therapist, dentist, etc.) tracked for a Person.
///
/// Shape is identical to `Medications`: every sensitive field (name,
/// kind, specialty, phone, address, portal URL, notes) lives inside the
/// encrypted `payload` blob under the owning Person's key. Only the
/// metadata needed for sorting, soft-delete, and Phase 2 sync lives in
/// the clear. In particular, `kind` is *not* plaintext — we don't need
/// indexed filtering by kind at our expected list sizes, and keeping it
/// inside the envelope is one less PII leak if a raw DB file is ever
/// exfiltrated.
///
/// Introduced in schema v5; see `AppDatabase.migration`.
@DataClassName('CareProviderRow')
class CareProviders extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person's id. Not a declared SQL foreign key — Phase 2 sync
  /// needs to tolerate arrival order (a provider row may sync before
  /// its Person row).
  TextColumn get personId => text()();

  /// Epoch milliseconds.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not archived.
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
