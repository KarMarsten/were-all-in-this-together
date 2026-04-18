import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/people/data/encrypted_person_payload.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';

/// Thrown when a Person row exists in the database but no encryption key is
/// available for it on this device. This is a data-integrity signal, not an
/// expected state — callers should surface it rather than swallowing it.
///
/// Implemented as an [Exception] (not [Error]) because it represents a
/// runtime condition — e.g. an interrupted device restore that leaves the
/// DB restored but the Keychain empty — not a programming bug.
class PersonKeyMissingError implements Exception {
  PersonKeyMissingError(this.personId);

  final String personId;

  @override
  String toString() =>
      'PersonKeyMissingError: no encryption key found for Person $personId '
      '(key storage has drifted out of sync with the database)';
}

/// Thrown on writes that reference an id the database doesn't have (e.g.
/// updating a Person that was deleted concurrently).
class PersonNotFoundError implements Exception {
  PersonNotFoundError(this.personId);

  final String personId;

  @override
  String toString() =>
      'PersonNotFoundError: no Person with id $personId in the database';
}

/// Repository for the People domain.
///
/// Responsibilities:
///
/// * Generate a fresh encryption key and UUID on every new Person.
/// * Encrypt sensitive fields under the Person's key with AAD that binds the
///   ciphertext to the Person id, so a blob can never be silently relocated
///   to another row.
/// * Maintain `createdAt`, `updatedAt`, `rowVersion` invariants.
/// * Treat soft-deleted rows as invisible to reads by default.
///
/// All read paths that cannot decrypt (missing key) either raise
/// [PersonKeyMissingError] ([findById], [update]) or quietly skip the row
/// ([listActive]) — the list view deliberately tolerates a bad row so the
/// picker keeps working while we surface the integrity problem elsewhere.
class PersonRepository {
  PersonRepository({
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

  /// Create a new Person. Generates a fresh key + id, persists the key to
  /// secure storage *before* writing the database row so we can never end
  /// up with an unopenable row if the process dies between calls.
  Future<Person> create({
    required String displayName,
    String? pronouns,
    DateTime? dob,
    String? preferredFramingNotes,
  }) async {
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'must not be empty',
      );
    }

    final id = _uuid.v4();
    final key = await _crypto.generateKey();
    await _keys.store(id, key);

    // Normalise all timestamps to UTC. DateTime equality in Dart compares
    // both the instant and the `isUtc` flag, so a local-time createdAt in
    // memory will NOT equal the UTC value reconstructed from the stored
    // epoch millis — we keep the whole repo in UTC to dodge that foot-gun.
    final now = _clock().toUtc();
    final payload = EncryptedPersonPayload(
      schemaVersion: EncryptedPersonPayload.currentSchemaVersion,
      displayName: displayName,
      pronouns: pronouns,
      dob: dob,
      preferredFramingNotes: preferredFramingNotes,
    );
    final encrypted = await _sealPayload(id, payload, key);

    await _db.into(_db.persons).insert(
          PersonsCompanion.insert(
            id: id,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return Person(
      id: id,
      displayName: displayName,
      pronouns: pronouns,
      dob: dob,
      preferredFramingNotes: preferredFramingNotes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Look up a single Person by id.
  ///
  /// * Returns `null` if no row with that id exists.
  /// * Returns `null` if the row exists but is soft-deleted. Same behaviour
  ///   as "no such id" on purpose — soft-deleted rows are tombstones for
  ///   Phase-2 sync reconciliation, not a feature callers consume.
  /// * Throws [PersonKeyMissingError] if the row exists and is active but
  ///   its key is missing on this device. This is a data-integrity issue,
  ///   not an expected state, so callers should surface it.
  Future<Person?> findById(String id) async {
    final row = await (_db.select(_db.persons)
          ..where(
            (p) => p.id.equals(id) & p.deletedAt.isNull(),
          ))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  /// All non-deleted Persons. Rows whose key is missing are skipped (see
  /// class docs); other decode failures propagate.
  Future<List<Person>> listActive() async {
    final rows = await (_db.select(_db.persons)
          ..where((p) => p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();

    final persons = <Person>[];
    for (final row in rows) {
      try {
        persons.add(await _decode(row));
      } on PersonKeyMissingError {
        // Deliberately swallowed — see class docs. A soft failure here keeps
        // the picker usable if one row's key ever goes missing.
        continue;
      }
    }
    return persons;
  }

  /// Persist the given Person's sensitive fields. Increments `rowVersion`
  /// and stamps `updatedAt`.
  Future<Person> update(Person updated) async {
    final key = await _keys.load(updated.id);
    if (key == null) {
      throw PersonKeyMissingError(updated.id);
    }

    final now = _clock().toUtc();
    final payload = EncryptedPersonPayload(
      schemaVersion: EncryptedPersonPayload.currentSchemaVersion,
      displayName: updated.displayName,
      pronouns: updated.pronouns,
      dob: updated.dob,
      preferredFramingNotes: updated.preferredFramingNotes,
    );
    final encrypted = await _sealPayload(updated.id, payload, key);

    final affected = await (_db.update(_db.persons)
          ..where((p) => p.id.equals(updated.id)))
        .write(
      PersonsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );
    if (affected == 0) {
      throw PersonNotFoundError(updated.id);
    }

    return updated.copyWith(
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  /// Mark a Person as deleted. Does not physically remove the row (Phase 2
  /// sync needs the tombstone) and does not delete the encryption key (that
  /// is a separate, more serious operation handled by the caller).
  Future<void> softDelete(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.persons)
          ..where((p) => p.id.equals(id) & p.deletedAt.isNull()))
        .write(
      PersonsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) {
      throw PersonNotFoundError(id);
    }
  }

  Future<EncryptedPayload> _sealPayload(
    String personId,
    EncryptedPersonPayload payload,
    SecretKey key,
  ) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(personId),
    );
  }

  Future<Person> _decode(PersonRow row) async {
    final key = await _keys.load(row.id);
    if (key == null) {
      throw PersonKeyMissingError(row.id);
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(row.id),
    );
    final payload = EncryptedPersonPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return Person(
      id: row.id,
      displayName: payload.displayName,
      pronouns: payload.pronouns,
      dob: payload.dob,
      preferredFramingNotes: payload.preferredFramingNotes,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  /// AAD binds a ciphertext to its row id. Without this, an attacker with
  /// write access to the DB (or the Phase-2 sync backend) could substitute
  /// one Person's payload for another's. Deliberately does not include the
  /// schema version — version drift is handled by the `v` field inside the
  /// plaintext JSON instead.
  List<int> _aadFor(String personId) =>
      utf8.encode('person:$personId:payload');
}

/// The application-wide [PersonRepository].
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
