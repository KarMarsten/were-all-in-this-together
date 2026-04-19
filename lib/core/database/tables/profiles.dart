import 'package:drift/drift.dart';

/// One row per Person — the encrypted "living document" baseline
/// fields that don't yet live in structured `ProfileEntry` children.
///
/// Exactly **one** active row per `personId` is enforced via
/// [uniqueKeys]. Archive (soft-delete) frees the slot for a future
/// re-create if we ever need it; Phase 1 UI keeps a single profile
/// per Person and uses **update** only after the first create.
///
/// Storage:
///
/// * `personId` — plaintext; the join key and uniqueness scope.
/// * `payload` — envelope-encrypted JSON (`EncryptedProfilePayload`)
///   under the owning Person's key: communication notes, sleep and
///   appetite baselines. Everything sensitive stays in the blob so
///   we never ship plaintext medical / support narrative in SQLite.
///
/// Introduced in schema v9; see `AppDatabase.migration`.
@DataClassName('ProfileRow')
class Profiles extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person. Unique per non-deleted row; see [uniqueKeys].
  TextColumn get personId => text()();

  /// Epoch milliseconds.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not archived.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter.
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  /// Phase 2 sync debugging.
  TextColumn get lastWriterDeviceId => text().nullable()();

  /// Key generation for ciphertext.
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  /// Envelope-encrypted `EncryptedProfilePayload` bytes.
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {personId},
      ];
}
