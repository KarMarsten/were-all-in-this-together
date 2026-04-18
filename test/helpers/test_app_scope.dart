import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` is not exported from the main flutter_riverpod barrel in 3.x.
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';

import 'in_memory_key_storage.dart';

/// Wraps the app in a [ProviderScope] with an in-memory [AppDatabase] and
/// [InMemoryKeyStorage], so widget tests don't need the iOS Keychain / path
/// provider / sqlite plugin channels.
///
/// Each call builds fresh state so tests don't leak into each other.
Widget buildTestApp({List<Override> extraOverrides = const []}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      keyStorageProvider.overrideWith((_) => InMemoryKeyStorage()),
      ...extraOverrides,
    ],
    child: const App(),
  );
}
