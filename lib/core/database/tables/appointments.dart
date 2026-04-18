import 'package:drift/drift.dart';

/// Appointments table — one row per scheduled visit / meeting tracked
/// for a Person (pediatrician follow-up, IEP review, therapy session,
/// dental cleaning).
///
/// All sensitive content — title, location, notes, reminder lead,
/// duration, provider link — lives inside the encrypted `payload`
/// blob under the owning Person's key. The two exceptions that are
/// plaintext on the row are:
///
/// * `scheduledAt` — needed for range queries ("what's upcoming in
///   the next 7 days", "today's appointments") without decrypting
///   every row, and needed for background notification scheduling
///   without holding a key in memory at boot. Mirrors how
///   `DoseLogs.scheduledAtMs` is handled.
/// * `deletedAt` / timestamps / `rowVersion` — standard Phase 2 sync
///   metadata, same pattern as every other table in this app.
///
/// A plaintext timestamp leaks "the user has *something* scheduled
/// at 2pm Monday", not *what* it is. Since the OS has to see
/// notification fire times regardless, we're not widening the
/// attack surface by caching that timestamp here.
///
/// Introduced in schema v7; see `AppDatabase.migration`.
@DataClassName('AppointmentRow')
class Appointments extends Table {
  /// Client-generated UUID v4.
  TextColumn get id => text()();

  /// Owning Person's id. Not a declared SQL foreign key — Phase 2
  /// sync needs to tolerate arrival order (an appointment may sync
  /// before its Person row).
  TextColumn get personId => text()();

  /// Epoch milliseconds (UTC instant) at which the appointment
  /// starts. Plaintext on purpose — see class doc.
  IntColumn get scheduledAt => integer()();

  /// Epoch milliseconds.
  IntColumn get createdAt => integer()();

  /// Epoch milliseconds.
  IntColumn get updatedAt => integer()();

  /// Epoch milliseconds; `null` means not archived.
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
