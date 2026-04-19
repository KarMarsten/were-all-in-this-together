import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/profile/data/encrypted_profile_payload.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile.dart';

/// Thrown when a profile row exists for a Person but that Person's
/// encryption key is missing on this device.
class ProfileKeyMissingError implements Exception {
  ProfileKeyMissingError({
    required this.profileId,
    required this.personId,
  });

  final String profileId;
  final String personId;

  @override
  String toString() =>
      'ProfileKeyMissingError: no encryption key found for Person '
      '$personId while resolving profile $profileId';
}

/// Thrown on writes that reference an id that doesn't exist.
class ProfileNotFoundError implements Exception {
  ProfileNotFoundError(this.profileId);

  final String profileId;

  @override
  String toString() => 'ProfileNotFoundError: no profile with id $profileId';
}

/// Repository for the per-Person [Profile] row.
///
/// Encrypts all narrative fields under the owning Person's key. AAD
/// binds each ciphertext to both the profile id and the Person id.
class ProfileRepository {
  ProfileRepository({
    required AppDatabase database,
    required CryptoService crypto,
    required KeyStorage keys,
    Uuid? uuidGenerator,
    DateTime Function()? clock,
  })  : _db = database,
        _crypto = crypto,
        _keys = keys,
        _uuid = uuidGenerator ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final CryptoService _crypto;
  final KeyStorage _keys;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Returns the profile for [personId], creating an empty row on
  /// first access. If a tombstoned row exists, clears `deletedAt`
  /// so the user can keep editing (Phase 1 rarely archives profiles).
  Future<Profile> getOrCreateForPerson(String personId) async {
    final key = await _keys.load(personId);
    if (key == null) {
      throw ProfileKeyMissingError(
        profileId: '(not-yet-created)',
        personId: personId,
      );
    }

    final existing = await (_db.select(_db.profiles)
          ..where((p) => p.personId.equals(personId)))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.deletedAt != null) {
        final now = _clock().toUtc().millisecondsSinceEpoch;
        await (_db.update(_db.profiles)..where((p) => p.id.equals(existing.id)))
            .write(
          ProfilesCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
        final restored = await (_db.select(_db.profiles)
              ..where((p) => p.id.equals(existing.id)))
            .getSingle();
        return _decode(restored);
      }
      return _decode(existing);
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    const payload = EncryptedProfilePayload(
      schemaVersion: EncryptedProfilePayload.currentSchemaVersion,
    );
    final encrypted = await _sealPayload(
      profileId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db.into(_db.profiles).insert(
          ProfilesCompanion.insert(
            id: id,
            personId: personId,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return Profile(
      id: id,
      personId: personId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Persist updated narrative fields. Bumps `rowVersion`.
  Future<Profile> update(Profile updated) async {
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw ProfileKeyMissingError(
        profileId: updated.id,
        personId: updated.personId,
      );
    }

    final row = await (_db.select(_db.profiles)
          ..where((p) => p.id.equals(updated.id)))
        .getSingleOrNull();
    if (row == null) {
      throw ProfileNotFoundError(updated.id);
    }
    if (row.personId != updated.personId) {
      throw StateError(
        'ProfileRepository.update refused: attempted to change personId.',
      );
    }

    final now = _clock().toUtc();
    final payload = EncryptedProfilePayload(
      schemaVersion: EncryptedProfilePayload.currentSchemaVersion,
      communicationNotes: updated.communicationNotes,
      sleepBaseline: updated.sleepBaseline,
      appetiteBaseline: updated.appetiteBaseline,
    );
    final encrypted = await _sealPayload(
      profileId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(_db.profiles)..where((p) => p.id.equals(updated.id)))
        .write(
      ProfilesCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  Future<EncryptedPayload> _sealPayload({
    required String profileId,
    required String personId,
    required EncryptedProfilePayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(profileId: profileId, personId: personId),
    );
  }

  Future<Profile> _decode(ProfileRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw ProfileKeyMissingError(
        profileId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(profileId: row.id, personId: row.personId),
    );
    final payload = EncryptedProfilePayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    final created =
        DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true);
    final updated =
        DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true);
    final deleted = row.deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true);
    return Profile(
      id: row.id,
      personId: row.personId,
      createdAt: created,
      updatedAt: updated,
      communicationNotes: payload.communicationNotes,
      sleepBaseline: payload.sleepBaseline,
      appetiteBaseline: payload.appetiteBaseline,
      deletedAt: deleted,
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  List<int> _aadFor({
    required String profileId,
    required String personId,
  }) =>
      utf8.encode('profile:$personId:$profileId:payload');
}

/// Application-wide [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
