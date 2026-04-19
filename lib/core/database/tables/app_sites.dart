import 'package:drift/drift.dart';

/// Apps & Sites — portal URLs, telehealth, IEP tools (never passwords).
///
/// Title, URL, and notes are envelope-encrypted in [payload]. AAD binds each
/// blob to `appSite:$personId:$id:payload`.
///
/// Introduced in schema v12.
@DataClassName('AppSiteRow')
class AppSites extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text()();

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
