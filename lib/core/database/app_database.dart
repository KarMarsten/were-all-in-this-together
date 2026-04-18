import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/core/database/tables/dose_logs.dart';
import 'package:were_all_in_this_together/core/database/tables/medication_groups.dart';
import 'package:were_all_in_this_together/core/database/tables/medications.dart';
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
///
/// Schema history:
///
/// * **v1** — Persons.
/// * **v2** — adds Medications.
/// * **v3** — adds DoseLogs.
/// * **v4** — adds MedicationGroups.
@DriftDatabase(tables: [Persons, Medications, DoseLogs, MedicationGroups])
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Each branch must be idempotent w.r.t. its `from` — never assume
          // previous branches ran. That way a user who skipped several
          // versions (e.g. long-dormant install) still lands on the right
          // schema without rerunning finished migrations.
          if (from < 2) {
            await m.createTable(medications);
          }
          if (from < 3) {
            await m.createTable(doseLogs);
          }
          if (from < 4) {
            await m.createTable(medicationGroups);
          }
        },
      );
}

/// Application-wide database. Disposed when the provider container is
/// disposed (e.g. at app shutdown).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.forApp();
  ref.onDispose(db.close);
  return db;
});
