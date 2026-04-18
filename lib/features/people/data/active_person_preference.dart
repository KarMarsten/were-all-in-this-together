import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists which Person the user last chose as "active" on this device.
///
/// This is **device-local preference state**, not data. It's stored in
/// secure storage only because we already have that plumbing for keys —
/// the active-person id is a random UUID and is not itself sensitive.
///
/// If nothing has been chosen yet, or the stored id no longer corresponds
/// to an existing Person, [getActivePersonId] returns `null` and the UI
/// layer is expected to pick a sensible default (typically the oldest
/// Person in the roster).
abstract interface class ActivePersonPreference {
  Future<String?> getActivePersonId();
  Future<void> setActivePersonId(String? id);
}

/// Production implementation backed by [FlutterSecureStorage].
///
/// Uses a distinct key prefix (\`pref:active_person_id\`) so the roster-
/// introspection logic in `SecureKeyStorage.personIds()` (which filters on
/// \`person_key:\`) can't ever confuse a preference value for a real Person
/// key.
class SecureStorageActivePersonPreference implements ActivePersonPreference {
  SecureStorageActivePersonPreference({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String storageKey = 'pref:active_person_id';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getActivePersonId() => _storage.read(key: storageKey);

  @override
  Future<void> setActivePersonId(String? id) async {
    if (id == null) {
      await _storage.delete(key: storageKey);
    } else {
      await _storage.write(key: storageKey, value: id);
    }
  }
}

/// Application-wide [ActivePersonPreference]. Tests that don't want to
/// touch platform channels should override this with an in-memory fake.
final activePersonPreferenceProvider = Provider<ActivePersonPreference>(
  (ref) => SecureStorageActivePersonPreference(),
);
