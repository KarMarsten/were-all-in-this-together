import 'package:drift/drift.dart';

/// MedicationGroups table — a user-defined bundle of medications that
/// are tracked together (e.g. "Morning stack", "Before bed").
///
/// What's in the clear and why:
///
/// * `personId` — needed to scope queries to the active Person without
///   decrypting every row, consistent with `Medications` and `DoseLogs`.
/// * `createdAt` / `updatedAt` / `deletedAt` — required for Phase 2
///   sync conflict resolution and tombstone propagation.
/// * `rowVersion`, `keyVersion`, `lastWriterDeviceId` — sync bookkeeping.
///
/// What's encrypted and why:
///
/// * The group's `name` ("Morning meds", "Anti-seizure stack") is as
///   sensitive as any individual medication name.
/// * The group's `schedule` — times a user takes meds are a strong
///   behavioural fingerprint.
/// * The `members` list — pairing this with the plaintext
///   `medications.personId` column would let an attacker trivially
///   infer "these meds are co-taken", which is most of the value of
///   the group anyway.
///
/// All encrypted fields live in the `payload` blob, sealed under the
/// owning Person's key. AAD binds the ciphertext to `(groupId,
/// personId)` so a row cannot be relocated across groups or persons
/// even by an attacker with DB write access.
///
/// Note: schema v4. Introduced in the Medication Groups PR; see
/// `AppDatabase.migration`.
@DataClassName('MedicationGroupRow')
class MedicationGroups extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person. Not a declared SQL foreign key — same Phase 2
  /// arrival-order rationale as every other table in this schema.
  TextColumn get personId => text()();

  /// Epoch milliseconds; when the row was first written.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds; updated on every mutation.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` until archived. Keeping soft-delete
  /// symmetric with the other tables simplifies sync later.
  IntColumn get deletedAt => integer().nullable()();

  /// Monotonically increasing per-row counter, incremented on every
  /// write. Same semantics as elsewhere.
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  /// Which device last wrote this row. `null` in Phase 1.
  TextColumn get lastWriterDeviceId => text().nullable()();

  /// Which key generation decrypted this row's payload.
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`
  /// over an `EncryptedMedicationGroupPayload` JSON body.
  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
