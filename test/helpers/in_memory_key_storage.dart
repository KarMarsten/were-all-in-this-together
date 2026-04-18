import 'package:cryptography/cryptography.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';

/// Test double for [KeyStorage] that keeps keys in memory.
///
/// This lives in `test/` (not `lib/`) so it can't accidentally ship in the
/// production binary. Tests that need a working KeyStorage without the iOS
/// Keychain / Android Keystore plugin channels can override
/// `keyStorageProvider` with an instance of this.
class InMemoryKeyStorage implements KeyStorage {
  final Map<String, SecretKey> _keys = <String, SecretKey>{};

  /// Expose current entries for assertions. Copy, so callers can't mutate
  /// internal state.
  Map<String, SecretKey> get snapshot => Map.unmodifiable(_keys);

  @override
  Future<void> store(String personId, SecretKey key) async {
    _keys[personId] = key;
  }

  @override
  Future<SecretKey?> load(String personId) async => _keys[personId];

  @override
  Future<void> delete(String personId) async {
    _keys.remove(personId);
  }

  @override
  Future<Set<String>> personIds() async => _keys.keys.toSet();
}
