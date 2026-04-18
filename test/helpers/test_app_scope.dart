import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` is not exported from the main flutter_riverpod barrel in 3.x.
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:were_all_in_this_together/app.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/active_person_preference.dart';

import 'in_memory_active_person_preference.dart';
import 'in_memory_key_storage.dart';

/// Wraps the app in a [ProviderScope] with test doubles for every provider
/// that would otherwise touch a platform channel: [AppDatabase],
/// [KeyStorage], and [ActivePersonPreference].
///
/// Each call builds fresh state so tests don't leak into each other.
Widget buildTestApp({
  List<Override> extraOverrides = const [],
  String? initialActivePersonId,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      keyStorageProvider.overrideWith((_) => InMemoryKeyStorage()),
      activePersonPreferenceProvider.overrideWith(
        (_) => InMemoryActivePersonPreference(initialId: initialActivePersonId),
      ),
      ...extraOverrides,
    ],
    child: const App(),
  );
}
