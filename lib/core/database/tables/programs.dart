import 'package:drift/drift.dart';

/// Programs — schools, camps, after-care, and similar per-Person contacts.
///
/// `kind` is a small plaintext enum index for grouping on the list screen.
/// `name`, `notes`, and `phone` live in the encrypted [payload] under the
/// Person's key. AAD binds each blob to `program:$personId:$id:payload`.
///
/// Introduced in schema v12.
@DataClassName('ProgramRow')
class Programs extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text()();

  /// Program-kind enum index — append-only; unknown indices map to
  /// "other" at decode time.
  IntColumn get kind => integer()();

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
