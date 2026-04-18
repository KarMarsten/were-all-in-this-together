import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/database/tables/persons.dart';

part 'app_database.g.dart';

/// The single SQLite database for all local data.
///
/// At runtime, [AppDatabase.forApp] opens a file-backed database in the
/// platform's application-documents directory. Tests and integration tests
/// instead construct an in-memory database directly:
///
/// ```dart
/// final db = AppDatabase(NativeDatabase.memory());
/// ```
@DriftDatabase(tables: [Persons])
class AppDatabase extends _$AppDatabase {
  // `super.executor` would be nicer but the drift-generated base constructor
  // names its parameter `e`, which would leak into our call sites.
  // ignore: use_super_parameters
  AppDatabase(QueryExecutor executor) : super(executor);

  /// Opens the production file-backed database. The name pins the filename
  /// inside the app-documents directory to `were_all_in_this_together.sqlite`.
  factory AppDatabase.forApp() =>
      AppDatabase(driftDatabase(name: 'were_all_in_this_together'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // No onUpgrade handlers yet; this is schema v1.
      );
}

/// Application-wide database. Disposed when the provider container is
/// disposed (e.g. at app shutdown).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.forApp();
  ref.onDispose(db.close);
  return db;
});
