import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists per-Person symmetric keys to a platform-appropriate secure store.
///
/// Every Person has its own 256-bit key. Separating keys per Person — rather
/// than one key per Household or per User — means a parent can legitimately
/// share access to one Person's records (e.g. their child's) without exposing
/// another Person's records (e.g. their own self-management).
///
/// Implementations:
/// * [SecureKeyStorage] — the real thing, backed by iOS Keychain / Android
///   Keystore via `flutter_secure_storage`. Used at runtime.
/// * `InMemoryKeyStorage` in `test/helpers/` — a test double usable in widget
///   and unit tests to avoid depending on platform channels.
abstract interface class KeyStorage {
  /// Persist [key] under [personId]. Overwrites any existing entry for the
  /// same Person — that is *not* key rotation, which requires re-encrypting
  /// the Person's data under the new key and is handled at a higher layer.
  Future<void> store(String personId, SecretKey key);

  /// Load the key previously stored for [personId], or `null` if none.
  ///
  /// A null return means "this Person has no key on this device" — which is
  /// distinct from "the key failed to decrypt". Downstream code should treat
  /// it as "data for this Person is not openable here" and, in Phase 2,
  /// trigger the pairing flow to acquire the key from another device.
  Future<SecretKey?> load(String personId);

  /// Delete the stored key for [personId]. Safe to call when no key exists.
  ///
  /// Once a key is deleted, any data previously encrypted under it on this
  /// device becomes unopenable *locally*. That's by design: deleting the key
  /// is how we revoke access.
  Future<void> delete(String personId);

  /// Return the set of Person ids that currently have a key on this device.
  /// Useful for diagnostics and for reconciling the key store against the
  /// database (e.g. warn on orphaned Persons / orphaned keys).
  Future<Set<String>> personIds();
}

/// Production [KeyStorage]. Stores each Person key as base64 under a
/// `person_key:<personId>` entry in the platform secure store.
///
/// **Keychain/Keystore options** are set to sensible Phase-1 defaults:
/// items are local to this device only, available after first unlock. When
/// Phase 2 adds cross-device sync we'll re-evaluate — switching Keychain
/// accessibility in place is not a no-op (items must be rewritten), so we
/// track that as an explicit migration rather than silently flipping a flag.
class SecureKeyStorage implements KeyStorage {
  SecureKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
          mOptions: MacOsOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  /// Namespacing prefix. If we ever persist other secrets through this same
  /// store (e.g. an auth refresh token in Phase 2), they'll live under a
  /// different prefix so `personIds()` stays honest.
  static const String keyPrefix = 'person_key:';

  @override
  Future<void> store(String personId, SecretKey key) async {
    _assertPersonId(personId);
    final bytes = await key.extractBytes();
    final encoded = base64Encode(bytes);
    await _storage.write(key: '$keyPrefix$personId', value: encoded);
  }

  @override
  Future<SecretKey?> load(String personId) async {
    _assertPersonId(personId);
    final encoded = await _storage.read(key: '$keyPrefix$personId');
    if (encoded == null) {
      return null;
    }
    return SecretKey(base64Decode(encoded));
  }

  @override
  Future<void> delete(String personId) async {
    _assertPersonId(personId);
    await _storage.delete(key: '$keyPrefix$personId');
  }

  @override
  Future<Set<String>> personIds() async {
    final all = await _storage.readAll();
    return all.keys
        .where((k) => k.startsWith(keyPrefix))
        .map((k) => k.substring(keyPrefix.length))
        .toSet();
  }

  void _assertPersonId(String personId) {
    if (personId.isEmpty) {
      throw ArgumentError.value(personId, 'personId', 'must not be empty');
    }
    if (personId.contains(':')) {
      // Guard against accidentally nested/ambiguous key paths.
      throw ArgumentError.value(
        personId,
        'personId',
        'must not contain ":"',
      );
    }
  }
}

/// Application-wide [KeyStorage]. Tests that don't care about platform
/// channels should override this provider with an `InMemoryKeyStorage`.
final keyStorageProvider = Provider<KeyStorage>(
  (ref) => SecureKeyStorage(),
);
