import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';

void main() {
  late CryptoService crypto;

  setUp(() {
    crypto = XChaCha20CryptoService();
  });

  group('XChaCha20CryptoService', () {
    test('round-trips plaintext', () async {
      final key = await crypto.generateKey();
      final plaintext = utf8.encode('Alex — they/them, born 2015-03-12');

      final encrypted = await crypto.encrypt(plaintext, key: key);
      final decrypted = await crypto.decrypt(encrypted, key: key);

      expect(decrypted, plaintext);
    });

    test('round-trips empty plaintext', () async {
      final key = await crypto.generateKey();

      final encrypted = await crypto.encrypt(const <int>[], key: key);
      final decrypted = await crypto.decrypt(encrypted, key: key);

      expect(decrypted, isEmpty);
    });

    test('two encryptions of the same plaintext produce different ciphertext',
        () async {
      final key = await crypto.generateKey();
      final plaintext = utf8.encode('same thing twice');

      final a = await crypto.encrypt(plaintext, key: key);
      final b = await crypto.encrypt(plaintext, key: key);

      expect(
        a.nonce,
        isNot(equals(b.nonce)),
        reason: 'encrypt() must use a fresh random nonce per call',
      );
      expect(a.ciphertext, isNot(equals(b.ciphertext)));
    });

    test('decrypt with the wrong key fails authentication', () async {
      final key = await crypto.generateKey();
      final wrongKey = await crypto.generateKey();
      final plaintext = utf8.encode('secret stuff');

      final encrypted = await crypto.encrypt(plaintext, key: key);

      await expectLater(
        crypto.decrypt(encrypted, key: wrongKey),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('tampered ciphertext fails authentication', () async {
      final key = await crypto.generateKey();
      final plaintext = utf8.encode('original');

      final encrypted = await crypto.encrypt(plaintext, key: key);
      final tampered = EncryptedPayload(
        version: encrypted.version,
        nonce: encrypted.nonce,
        mac: encrypted.mac,
        ciphertext: Uint8List.fromList(
          [encrypted.ciphertext[0] ^ 1, ...encrypted.ciphertext.skip(1)],
        ),
      );

      await expectLater(
        crypto.decrypt(tampered, key: key),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('tampered MAC fails authentication', () async {
      final key = await crypto.generateKey();
      final plaintext = utf8.encode('original');

      final encrypted = await crypto.encrypt(plaintext, key: key);
      final tampered = EncryptedPayload(
        version: encrypted.version,
        nonce: encrypted.nonce,
        mac: Uint8List.fromList(
          [encrypted.mac[0] ^ 1, ...encrypted.mac.skip(1)],
        ),
        ciphertext: encrypted.ciphertext,
      );

      await expectLater(
        crypto.decrypt(tampered, key: key),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('AAD binds ciphertext: mismatched AAD fails authentication', () async {
      final key = await crypto.generateKey();
      final plaintext = utf8.encode('payload');
      final aad = utf8.encode('personId=alex');
      final wrongAad = utf8.encode('personId=sam');

      final encrypted = await crypto.encrypt(plaintext, key: key, aad: aad);

      // Correct AAD opens the payload.
      final decrypted = await crypto.decrypt(encrypted, key: key, aad: aad);
      expect(decrypted, plaintext);

      // Wrong AAD does not.
      await expectLater(
        crypto.decrypt(encrypted, key: key, aad: wrongAad),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('generated keys are 32 bytes and differ from run to run', () async {
      final a = await crypto.generateKey();
      final b = await crypto.generateKey();

      final aBytes = await a.extractBytes();
      final bBytes = await b.extractBytes();

      expect(aBytes.length, 32);
      expect(bBytes.length, 32);
      expect(aBytes, isNot(equals(bBytes)));
    });
  });

  group('EncryptedPayload serialisation', () {
    test('toBytes / fromBytes round-trip preserves every field', () {
      final payload = EncryptedPayload(
        version: EncryptedPayload.currentVersion,
        nonce: Uint8List.fromList(List.generate(24, (i) => i)),
        mac: Uint8List.fromList(List.generate(16, (i) => i + 100)),
        ciphertext: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
      );

      final bytes = payload.toBytes();
      final roundTripped = EncryptedPayload.fromBytes(bytes);

      expect(roundTripped.version, payload.version);
      expect(roundTripped.nonce, payload.nonce);
      expect(roundTripped.mac, payload.mac);
      expect(roundTripped.ciphertext, payload.ciphertext);
    });

    test('toBytes produces the expected byte-layout length', () {
      final payload = EncryptedPayload(
        version: EncryptedPayload.currentVersion,
        nonce: Uint8List(24),
        mac: Uint8List(16),
        ciphertext: Uint8List(10),
      );

      expect(payload.toBytes().length, 1 + 24 + 16 + 10);
    });

    test('fromBytes rejects unsupported versions', () {
      final bytes = Uint8List.fromList([
        99,
        ...List<int>.filled(24, 0),
        ...List<int>.filled(16, 0),
        ...List<int>.filled(4, 0),
      ]);

      expect(
        () => EncryptedPayload.fromBytes(bytes),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('fromBytes rejects inputs shorter than the header', () {
      expect(
        () => EncryptedPayload.fromBytes(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('end-to-end: encrypt -> toBytes -> fromBytes -> decrypt', () async {
      final key = await crypto.generateKey();
      final plaintext = utf8.encode('store me then load me');

      final envelope = await crypto.encrypt(plaintext, key: key);
      final bytes = envelope.toBytes();
      final restored = EncryptedPayload.fromBytes(bytes);
      final decrypted = await crypto.decrypt(restored, key: key);

      expect(decrypted, plaintext);
    });
  });
}
