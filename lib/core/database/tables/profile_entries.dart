import 'package:drift/drift.dart';

/// Child rows of a profile — stims, preferences, routine blocks,
/// triggers, what helps, early signs, etc.
///
/// Plaintext on the row: `profileId`, `personId` (denormalised for the
/// same key-load pattern as `milestones.personId`), `section`, `status`,
/// `parentEntryId`, optional `firstNoted` / `lastNoted` epoch ms — enough
/// to filter and sort lists without decrypting every payload.
///
/// `payload` holds envelope-encrypted JSON (label + details narrative)
/// for the entry.
///
/// Introduced in schema v10; see `AppDatabase.migration`.
@DataClassName('ProfileEntryRow')
class ProfileEntries extends Table {
  TextColumn get id => text()();

  TextColumn get profileId => text()();

  /// Owning Person (denormalised from the profile row's `person_id`).
  TextColumn get personId => text()();

  /// `ProfileEntrySection.index`. Append-only enum policy.
  IntColumn get section => integer()();

  /// `ProfileEntryStatus.index`.
  IntColumn get status => integer()();

  TextColumn get parentEntryId => text().nullable()();

  IntColumn get firstNoted => integer().nullable()();

  IntColumn get lastNoted => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  IntColumn get rowVersion => integer().withDefault(const Constant(1))();

  TextColumn get lastWriterDeviceId => text().nullable()();

  IntColumn get keyVersion => integer().withDefault(const Constant(1))();

  BlobColumn get payload => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
