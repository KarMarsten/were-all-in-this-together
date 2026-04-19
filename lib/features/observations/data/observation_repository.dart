import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/observations/data/encrypted_observation_payload.dart';
import 'package:were_all_in_this_together/features/observations/domain/observation.dart';

/// Thrown when the Person key is missing for an observation row.
class ObservationKeyMissingError implements Exception {
  ObservationKeyMissingError({
    required this.observationId,
    required this.personId,
  });

  final String observationId;
  final String personId;

  @override
  String toString() =>
      'ObservationKeyMissingError: no encryption key found for Person '
      '$personId while resolving observation $observationId';
}

/// Thrown on writes that reference a missing observation id.
class ObservationNotFoundError implements Exception {
  ObservationNotFoundError(this.observationId);

  final String observationId;

  @override
  String toString() =>
      'ObservationNotFoundError: no observation with id $observationId';
}

/// Thrown when `profileEntryId` does not resolve for this Person.
class ObservationInvalidProfileEntryError implements Exception {
  ObservationInvalidProfileEntryError(this.message);

  final String message;

  @override
  String toString() => 'ObservationInvalidProfileEntryError: $message';
}

/// Repository for dated "Notes" timeline rows.
///
/// Encrypts `label`, `notes`, and `tags` under the Person key. AAD
/// binds each blob to the observation id and Person id.
class ObservationRepository {
  ObservationRepository({
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

  Future<Observation> create({
    required String personId,
    required DateTime observedAt,
    required ObservationCategory category,
    required String label,
    String? notes,
    List<String> tags = const [],
    String? profileEntryId,
  }) async {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }

    final key = await _keys.load(personId);
    if (key == null) {
      throw ObservationKeyMissingError(
        observationId: '(not-yet-created)',
        personId: personId,
      );
    }

    await _assertProfileEntryLink(
      personId: personId,
      profileEntryId: profileEntryId,
    );

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final observed = observedAt.toUtc();
    final tagList = _normalizeTags(tags);
    final payload = EncryptedObservationPayload(
      schemaVersion: EncryptedObservationPayload.currentSchemaVersion,
      label: label.trim(),
      notes: notes,
      tags: tagList,
    );
    final encrypted = await _sealPayload(
      observationId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db
        .into(_db.observations)
        .insert(
          ObservationsCompanion.insert(
            id: id,
            personId: personId,
            observedAt: observed.millisecondsSinceEpoch,
            category: category.index,
            profileEntryId: Value(profileEntryId),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return Observation(
      id: id,
      personId: personId,
      observedAt: observed,
      category: category,
      label: label.trim(),
      createdAt: now,
      updatedAt: now,
      profileEntryId: profileEntryId,
      notes: notes,
      tags: tagList,
    );
  }

  Future<Observation?> findById(String id) async {
    final row = await (_db.select(
      _db.observations,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  Future<List<Observation>> listActiveForPerson(String personId) async {
    final rows =
        await (_db.select(_db.observations)
              ..where(
                (o) => o.personId.equals(personId) & o.deletedAt.isNull(),
              )
              ..orderBy([
                (o) => OrderingTerm(
                  expression: o.observedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return _decodeMany(rows);
  }

  Future<List<Observation>> listArchivedForPerson(String personId) async {
    final rows =
        await (_db.select(_db.observations)
              ..where(
                (o) => o.personId.equals(personId) & o.deletedAt.isNotNull(),
              )
              ..orderBy([
                (o) => OrderingTerm(
                  expression: o.deletedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return _decodeMany(rows);
  }

  Future<Observation> update(Observation updated) async {
    if (updated.label.trim().isEmpty) {
      throw ArgumentError.value(updated.label, 'label', 'must not be empty');
    }

    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw ObservationKeyMissingError(
        observationId: updated.id,
        personId: updated.personId,
      );
    }

    final existing = await (_db.select(
      _db.observations,
    )..where((o) => o.id.equals(updated.id))).getSingleOrNull();
    if (existing == null) {
      throw ObservationNotFoundError(updated.id);
    }
    if (existing.personId != updated.personId) {
      throw StateError(
        'ObservationRepository.update refused: attempted to change '
        'personId.',
      );
    }

    await _assertProfileEntryLink(
      personId: updated.personId,
      profileEntryId: updated.profileEntryId,
    );

    final now = _clock().toUtc();
    final observed = updated.observedAt.toUtc();
    final tagList = _normalizeTags(updated.tags);
    final payload = EncryptedObservationPayload(
      schemaVersion: EncryptedObservationPayload.currentSchemaVersion,
      label: updated.label.trim(),
      notes: updated.notes,
      tags: tagList,
    );
    final encrypted = await _sealPayload(
      observationId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(
      _db.observations,
    )..where((o) => o.id.equals(updated.id))).write(
      ObservationsCompanion(
        observedAt: Value(observed.millisecondsSinceEpoch),
        category: Value(updated.category.index),
        profileEntryId: Value(updated.profileEntryId),
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      label: updated.label.trim(),
      tags: tagList,
      observedAt: observed,
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected =
        await (_db.update(
          _db.observations,
        )..where((o) => o.id.equals(id) & o.deletedAt.isNull())).write(
          ObservationsCompanion(
            updatedAt: Value(now.millisecondsSinceEpoch),
            deletedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
    if (affected == 0) {
      throw ObservationNotFoundError(id);
    }
  }

  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected =
        await (_db.update(
          _db.observations,
        )..where((o) => o.id.equals(id) & o.deletedAt.isNotNull())).write(
          ObservationsCompanion(
            updatedAt: Value(now.millisecondsSinceEpoch),
            deletedAt: const Value(null),
          ),
        );
    if (affected == 0) {
      throw ObservationNotFoundError(id);
    }
  }

  Future<void> _assertProfileEntryLink({
    required String personId,
    String? profileEntryId,
  }) async {
    final raw = profileEntryId?.trim();
    if (raw == null || raw.isEmpty) return;
    final row = await (_db.select(
      _db.profileEntries,
    )..where((e) => e.id.equals(raw))).getSingleOrNull();
    if (row == null) {
      throw ObservationInvalidProfileEntryError(
        'No profile entry with that id.',
      );
    }
    if (row.personId != personId) {
      throw ObservationInvalidProfileEntryError(
        'That profile line belongs to someone else.',
      );
    }
  }

  List<String> _normalizeTags(List<String> tags) {
    final out = <String>[];
    final seen = <String>{};
    for (final t in tags) {
      final s = t.trim();
      if (s.isEmpty) continue;
      final key = s.toLowerCase();
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  Future<List<Observation>> _decodeMany(List<ObservationRow> rows) async {
    final out = <Observation>[];
    for (final row in rows) {
      try {
        out.add(await _decode(row));
      } on ObservationKeyMissingError {
        continue;
      }
    }
    return out;
  }

  Future<EncryptedPayload> _sealPayload({
    required String observationId,
    required String personId,
    required EncryptedObservationPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(observationId: observationId, personId: personId),
    );
  }

  Future<Observation> _decode(ObservationRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw ObservationKeyMissingError(
        observationId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(observationId: row.id, personId: row.personId),
    );
    final payload = EncryptedObservationPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return Observation(
      id: row.id,
      personId: row.personId,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        row.observedAt,
        isUtc: true,
      ),
      category: _categoryFromIndex(row.category),
      label: payload.label,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      profileEntryId: row.profileEntryId,
      notes: payload.notes,
      tags: payload.tags,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  ObservationCategory _categoryFromIndex(int index) {
    if (index < 0 || index >= ObservationCategory.values.length) {
      return ObservationCategory.other;
    }
    return ObservationCategory.values[index];
  }

  List<int> _aadFor({
    required String observationId,
    required String personId,
  }) => utf8.encode('observation:$personId:$observationId:payload');
}

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  return ObservationRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
