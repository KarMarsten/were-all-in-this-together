import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';

/// Authenticated symmetric encryption for per-Person row payloads.
///
/// The service takes a [SecretKey] (the caller's responsibility to source —
/// typically from device-local secure storage, scoped to a single Person) and
/// produces/consumes [EncryptedPayload] envelopes.
///
/// Properties we care about here:
///
/// * **Authenticated encryption with associated data (AEAD).** A wrong key, a
///   tampered ciphertext, or a mismatched `aad` all fail decryption the same
///   way: by throwing. Callers should not attempt to "recover" partial data.
/// * **Fresh nonce per call.** `encrypt` generates a new random nonce every
///   time; the same plaintext encrypted twice produces different ciphertext,
///   which matters for privacy against an observer who sees repeated rows.
/// * **No key material leaks through the interface.** Keys are passed in as
///   opaque [SecretKey]s; the service never returns raw bytes.
abstract interface class CryptoService {
  /// Encrypt [plaintext] under [key]. Any bytes supplied in [aad] are
  /// authenticated but not encrypted; a common use is to bind a payload to
  /// its row id so a ciphertext can't silently be moved between rows.
  Future<EncryptedPayload> encrypt(
    List<int> plaintext, {
    required SecretKey key,
    List<int> aad = const [],
  });

  /// Decrypt [payload] under [key]. Throws [SecretBoxAuthenticationError] on
  /// any form of tamper, wrong key, or AAD mismatch.
  Future<Uint8List> decrypt(
    EncryptedPayload payload, {
    required SecretKey key,
    List<int> aad = const [],
  });

  /// Generate a fresh 256-bit symmetric key. Intended to be called once per
  /// Person at creation time and then handed to the `KeyStorage` layer
  /// (introduced in a follow-up PR) for persistence to the device Keychain.
  Future<SecretKey> generateKey();
}

/// XChaCha20-Poly1305 implementation.
///
/// XChaCha20 (as opposed to stock ChaCha20) is chosen because its 192-bit
/// nonce makes *random* nonces safe without a device-level counter. In an
/// offline-first app with multiple devices that may encrypt concurrently and
/// can't coordinate a nonce counter, this property is load-bearing.
class XChaCha20CryptoService implements CryptoService {
  XChaCha20CryptoService({Cipher? cipher})
      : _cipher = cipher ?? Xchacha20.poly1305Aead();

  final Cipher _cipher;

  @override
  Future<EncryptedPayload> encrypt(
    List<int> plaintext, {
    required SecretKey key,
    List<int> aad = const [],
  }) async {
    final box = await _cipher.encrypt(
      plaintext,
      secretKey: key,
      aad: aad,
    );
    return EncryptedPayload(
      version: EncryptedPayload.currentVersion,
      nonce: Uint8List.fromList(box.nonce),
      mac: Uint8List.fromList(box.mac.bytes),
      ciphertext: Uint8List.fromList(box.cipherText),
    );
  }

  @override
  Future<Uint8List> decrypt(
    EncryptedPayload payload, {
    required SecretKey key,
    List<int> aad = const [],
  }) async {
    final box = SecretBox(
      payload.ciphertext,
      nonce: payload.nonce,
      mac: Mac(payload.mac),
    );
    final plaintext = await _cipher.decrypt(
      box,
      secretKey: key,
      aad: aad,
    );
    return Uint8List.fromList(plaintext);
  }

  @override
  Future<SecretKey> generateKey() => _cipher.newSecretKey();
}
