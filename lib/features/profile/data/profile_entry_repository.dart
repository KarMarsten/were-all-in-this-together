import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/profile/data/encrypted_profile_entry_payload.dart';
import 'package:were_all_in_this_together/features/profile/data/profile_repository.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';

/// Thrown when decrypting a row requires a Person key that is not on
/// this device.
class ProfileEntryKeyMissingError implements Exception {
  ProfileEntryKeyMissingError({
    required this.entryId,
    required this.personId,
  });

  final String entryId;
  final String personId;

  @override
  String toString() =>
      'ProfileEntryKeyMissingError: no encryption key found for Person '
      '$personId while resolving profile entry $entryId';
}

/// Thrown when an update/archive targets a missing id.
class ProfileEntryNotFoundError implements Exception {
  ProfileEntryNotFoundError(this.entryId);

  final String entryId;

  @override
  String toString() =>
      'ProfileEntryNotFoundError: no profile entry with id $entryId';
}

/// Encrypted child rows under a profile — stims, preferences,
/// triggers, what helps, etc.
///
/// AAD binds each ciphertext to `personId` and the entry id.
class ProfileEntryRepository {
  ProfileEntryRepository({
    required AppDatabase database,
    required CryptoService crypto,
    required KeyStorage keys,
    Uuid? uuidGenerator,
    DateTime Function()? clock,
  }) : _db = database,
       _crypto = crypto,
       _keys = keys,
       _uuid = uuidGenerator ?? const Uuid(),
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final CryptoService _crypto;
  final KeyStorage _keys;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Creates a row under [profileId]. Verifies the profile exists and
  /// belongs to [personId].
  Future<ProfileEntry> create({
    required String profileId,
    required String personId,
    required ProfileEntrySection section,
    required String label,
    String? details,
    ProfileEntryStatus status = ProfileEntryStatus.active,
    String? parentEntryId,
    DateTime? firstNoted,
    DateTime? lastNoted,
  }) async {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }

    final prow = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (prow == null) {
      throw ProfileNotFoundError(profileId);
    }
    if (prow.personId != personId) {
      throw StateError(
        'ProfileEntryRepository.create refused: personId does not '
        'own this profile.',
      );
    }

    final key = await _keys.load(personId);
    if (key == null) {
      throw ProfileEntryKeyMissingError(
        entryId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final payload = EncryptedProfileEntryPayload(
      schemaVersion: EncryptedProfileEntryPayload.currentSchemaVersion,
      label: label.trim(),
      details: details,
    );
    final encrypted = await _sealPayload(
      entryId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db
        .into(_db.profileEntries)
        .insert(
          ProfileEntriesCompanion.insert(
            id: id,
            profileId: profileId,
            personId: personId,
            section: section.index,
            status: status.index,
            parentEntryId: Value(parentEntryId),
            firstNoted: Value(firstNoted?.toUtc().millisecondsSinceEpoch),
            lastNoted: Value(lastNoted?.toUtc().millisecondsSinceEpoch),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return ProfileEntry(
      id: id,
      profileId: profileId,
      personId: personId,
      section: section,
      status: status,
      label: label.trim(),
      createdAt: now,
      updatedAt: now,
      parentEntryId: parentEntryId,
      firstNoted: firstNoted,
      lastNoted: lastNoted,
      details: details,
    );
  }

  /// Active rows for [profileId], newest first. Skips rows whose key
  /// is missing (sync race). Asserts each row's [personId] matches.
  Future<List<ProfileEntry>> listActiveForProfile({
    required String profileId,
    required String personId,
  }) async {
    final rows =
        await (_db.select(_db.profileEntries)
              ..where(
                (e) => e.profileId.equals(profileId) & e.deletedAt.isNull(),
              )
              ..orderBy([
                (e) => OrderingTerm(
                  expression: e.createdAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return _decodeMany(rows, personId);
  }

  /// By id, including archived — for edit / deep links.
  Future<ProfileEntry?> findById(String id) async {
    final row = await (_db.select(
      _db.profileEntries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    try {
      return await _decode(row);
    } on ProfileEntryKeyMissingError {
      return null;
    }
  }

  Future<ProfileEntry> update(ProfileEntry updated) async {
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw ProfileEntryKeyMissingError(
        entryId: updated.id,
        personId: updated.personId,
      );
    }

    final row = await (_db.select(
      _db.profileEntries,
    )..where((e) => e.id.equals(updated.id))).getSingleOrNull();
    if (row == null) {
      throw ProfileEntryNotFoundError(updated.id);
    }
    if (row.personId != updated.personId ||
        row.profileId != updated.profileId) {
      throw StateError(
        'ProfileEntryRepository.update refused: id/person/profile mismatch.',
      );
    }

    final now = _clock().toUtc();
    final payload = EncryptedProfileEntryPayload(
      schemaVersion: EncryptedProfileEntryPayload.currentSchemaVersion,
      label: updated.label.trim(),
      details: updated.details,
    );
    final encrypted = await _sealPayload(
      entryId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(
      _db.profileEntries,
    )..where((e) => e.id.equals(updated.id))).write(
      ProfileEntriesCompanion(
        section: Value(updated.section.index),
        status: Value(updated.status.index),
        parentEntryId: Value(updated.parentEntryId),
        firstNoted: Value(
          updated.firstNoted?.toUtc().millisecondsSinceEpoch,
        ),
        lastNoted: Value(
          updated.lastNoted?.toUtc().millisecondsSinceEpoch,
        ),
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      label: updated.label.trim(),
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected =
        await (_db.update(
          _db.profileEntries,
        )..where((e) => e.id.equals(id) & e.deletedAt.isNull())).write(
          ProfileEntriesCompanion(
            updatedAt: Value(now.millisecondsSinceEpoch),
            deletedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
    if (affected == 0) {
      throw ProfileEntryNotFoundError(id);
    }
  }

  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected =
        await (_db.update(
          _db.profileEntries,
        )..where((e) => e.id.equals(id) & e.deletedAt.isNotNull())).write(
          ProfileEntriesCompanion(
            updatedAt: Value(now.millisecondsSinceEpoch),
            deletedAt: const Value(null),
          ),
        );
    if (affected == 0) {
      throw ProfileEntryNotFoundError(id);
    }
  }

  Future<List<ProfileEntry>> _decodeMany(
    List<ProfileEntryRow> rows,
    String expectedPersonId,
  ) async {
    final out = <ProfileEntry>[];
    for (final row in rows) {
      if (row.personId != expectedPersonId) {
        continue;
      }
      try {
        out.add(await _decode(row));
      } on ProfileEntryKeyMissingError {
        continue;
      }
    }
    return out;
  }

  Future<EncryptedPayload> _sealPayload({
    required String entryId,
    required String personId,
    required EncryptedProfileEntryPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(entryId: entryId, personId: personId),
    );
  }

  Future<ProfileEntry> _decode(ProfileEntryRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw ProfileEntryKeyMissingError(
        entryId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(entryId: row.id, personId: row.personId),
    );
    final payload = EncryptedProfileEntryPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return ProfileEntry(
      id: row.id,
      profileId: row.profileId,
      personId: row.personId,
      section: _sectionFromIndex(row.section),
      status: _statusFromIndex(row.status),
      label: payload.label,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      parentEntryId: row.parentEntryId,
      firstNoted: row.firstNoted == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.firstNoted!, isUtc: true),
      lastNoted: row.lastNoted == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastNoted!, isUtc: true),
      details: payload.details,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  ProfileEntrySection _sectionFromIndex(int index) {
    if (index < 0 || index >= ProfileEntrySection.values.length) {
      return ProfileEntrySection.other;
    }
    return ProfileEntrySection.values[index];
  }

  ProfileEntryStatus _statusFromIndex(int index) {
    if (index < 0 || index >= ProfileEntryStatus.values.length) {
      return ProfileEntryStatus.active;
    }
    return ProfileEntryStatus.values[index];
  }

  List<int> _aadFor({
    required String entryId,
    required String personId,
  }) => utf8.encode('profile_entry:$personId:$entryId:payload');
}

/// Application-wide [ProfileEntryRepository].
final profileEntryRepositoryProvider = Provider<ProfileEntryRepository>((ref) {
  return ProfileEntryRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
