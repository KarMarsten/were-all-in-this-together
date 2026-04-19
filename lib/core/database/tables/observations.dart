import 'package:drift/drift.dart';

/// Time-stamped narrative notes for a Person — the "Notes" timeline
/// that sits alongside Profile structured entries.
///
/// Plaintext on the row: `personId`, `observedAt` (UTC epoch ms for
/// sort/filter), `category` (small enum index), optional
/// `profileEntryId` (soft link to a profile entry for the same
/// Person — not a SQL FK).
///
/// `payload` holds envelope-encrypted JSON: `label`, optional
/// `notes`, and `tags` (string list).
///
/// Introduced in schema v11; see `AppDatabase.migration`.
@DataClassName('ObservationRow')
class Observations extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text()();

  IntColumn get observedAt => integer()();

  /// `ObservationCategory.index` — append-only enum policy.
  IntColumn get category => integer()();

  TextColumn get profileEntryId => text().nullable()();

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
