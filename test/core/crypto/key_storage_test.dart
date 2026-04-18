import 'package:flutter_test/flutter_test.dart';
import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';

import '../../helpers/in_memory_key_storage.dart';

/// Contract tests that any [KeyStorage] implementation must satisfy.
///
/// The production impl ([SecureKeyStorage]) is a thin base64 wrapper around
/// `flutter_secure_storage`; exercising its platform behaviour needs an
/// integration test with a real device/simulator and is handled separately.
/// Here we prove the behavioural contract against [InMemoryKeyStorage] so
/// downstream code can rely on the interface as documented.
void main() {
  late CryptoService crypto;
  late KeyStorage keys;

  setUp(() {
    crypto = XChaCha20CryptoService();
    keys = InMemoryKeyStorage();
  });

  group('KeyStorage contract', () {
    test('load returns null for an unknown personId', () async {
      expect(await keys.load('nobody'), isNull);
    });

    test('store then load returns the same key bytes', () async {
      final key = await crypto.generateKey();
      final original = await key.extractBytes();

      await keys.store('alex', key);
      final loaded = await keys.load('alex');
      final loadedBytes = await loaded!.extractBytes();

      expect(loadedBytes, original);
    });

    test('store overwrites an existing key for the same personId', () async {
      final first = await crypto.generateKey();
      final second = await crypto.generateKey();

      await keys.store('alex', first);
      await keys.store('alex', second);

      final loaded = await keys.load('alex');
      final loadedBytes = await loaded!.extractBytes();
      final secondBytes = await second.extractBytes();
      final firstBytes = await first.extractBytes();

      expect(loadedBytes, secondBytes);
      expect(loadedBytes, isNot(equals(firstBytes)));
    });

    test('keys are isolated per personId', () async {
      final alexKey = await crypto.generateKey();
      final samKey = await crypto.generateKey();

      await keys.store('alex', alexKey);
      await keys.store('sam', samKey);

      final loadedAlex = await keys.load('alex');
      final loadedSam = await keys.load('sam');

      expect(
        await loadedAlex!.extractBytes(),
        await alexKey.extractBytes(),
      );
      expect(
        await loadedSam!.extractBytes(),
        await samKey.extractBytes(),
      );
      expect(
        await loadedAlex.extractBytes(),
        isNot(equals(await loadedSam.extractBytes())),
      );
    });

    test('delete removes the key; subsequent load is null', () async {
      await keys.store('alex', await crypto.generateKey());
      expect(await keys.load('alex'), isNotNull);

      await keys.delete('alex');
      expect(await keys.load('alex'), isNull);
    });

    test('delete is idempotent / safe when the key is absent', () async {
      await keys.delete('never-stored');
      expect(await keys.load('never-stored'), isNull);
    });

    test('personIds lists only currently-stored entries', () async {
      expect(await keys.personIds(), isEmpty);

      await keys.store('alex', await crypto.generateKey());
      await keys.store('sam', await crypto.generateKey());
      expect(await keys.personIds(), {'alex', 'sam'});

      await keys.delete('alex');
      expect(await keys.personIds(), {'sam'});
    });
  });

  group('SecureKeyStorage input validation', () {
    // These don't need a platform channel — validation runs before any
    // plugin call.
    final store = SecureKeyStorage();

    test('rejects empty personId', () async {
      await expectLater(
        () => store.load(''),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => store.delete(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects personId containing ":"', () async {
      await expectLater(
        () => store.load('ambiguous:key'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('round-trip with CryptoService', () {
    test('a key loaded from storage can decrypt data encrypted with the '
        'original key', () async {
      final key = await crypto.generateKey();
      final plaintext = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

      final encrypted = await crypto.encrypt(plaintext, key: key);

      await keys.store('alex', key);
      final loaded = (await keys.load('alex'))!;

      final decrypted = await crypto.decrypt(encrypted, key: loaded);
      expect(decrypted, plaintext);
    });
  });
}
