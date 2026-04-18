import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/encrypted_medication_group_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_group.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Thrown when a medication-group row exists for a Person but that
/// Person's encryption key is missing on this device. Mirrors the
/// `*KeyMissingError` pattern across this module so callers catch one
/// predictable error shape.
class MedicationGroupKeyMissingError implements Exception {
  MedicationGroupKeyMissingError({
    required this.groupId,
    required this.personId,
  });

  final String groupId;
  final String personId;

  @override
  String toString() =>
      'MedicationGroupKeyMissingError: no encryption key found for '
      'Person $personId while resolving group $groupId';
}

/// Thrown when a mutation targets a groupId that doesn't exist.
class MedicationGroupNotFoundError implements Exception {
  MedicationGroupNotFoundError(this.groupId);

  final String groupId;

  @override
  String toString() =>
      'MedicationGroupNotFoundError: no medication group with id $groupId';
}

/// Repository for [MedicationGroup].
///
/// Storage model matches `MedicationRepository` exactly — envelope
/// encryption under the owning Person's key, AAD bound to
/// `(groupId, personId)`, soft-delete via `deletedAt`. The symmetry
/// is intentional: groups are just "meta meds", so they use the same
/// crypto envelope and sync bookkeeping.
///
/// Member validation deliberately lives outside this layer. Callers
/// (the form screen, the dose expander) decide what "valid members"
/// means — at this layer we faithfully persist the list the caller
/// provides. That keeps the repository pure CRUD and testable without
/// dragging in medication state.
class MedicationGroupRepository {
  MedicationGroupRepository({
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

  /// Create a new group for [personId]. [name] must be non-empty; we
  /// don't enforce uniqueness of group names at this layer because the
  /// display name is encrypted and the repository can't cheaply
  /// dedupe-check without decrypting every row.
  Future<MedicationGroup> create({
    required String personId,
    required String name,
    MedicationSchedule schedule = MedicationSchedule.asNeeded,
    List<String> memberMedicationIds = const <String>[],
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }

    final key = await _keys.load(personId);
    if (key == null) {
      throw MedicationGroupKeyMissingError(
        groupId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();

    final members = _normalizeMembers(memberMedicationIds);
    final payload = EncryptedMedicationGroupPayload(
      schemaVersion: EncryptedMedicationGroupPayload.currentSchemaVersion,
      name: name,
      schedule: schedule,
      memberMedicationIds: members,
    );
    final encrypted = await _sealPayload(
      groupId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db.into(_db.medicationGroups).insert(
          MedicationGroupsCompanion.insert(
            id: id,
            personId: personId,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return MedicationGroup(
      id: id,
      personId: personId,
      name: name,
      schedule: schedule,
      memberMedicationIds: members,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Look up a single group by id. Returns `null` for unknown ids and
  /// archived rows; callers wanting archived rows must use
  /// [listArchivedForPerson], matching the medication repo's contract.
  Future<MedicationGroup?> findById(String id) async {
    final row = await (_db.select(_db.medicationGroups)
          ..where((g) => g.id.equals(id) & g.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  /// All active (non-archived) groups for [personId], oldest first.
  /// Groups whose key is missing are skipped — same defensive stance
  /// as the medication repo (one bad row doesn't hide the rest).
  Future<List<MedicationGroup>> listActiveForPerson(String personId) async {
    final rows = await (_db.select(_db.medicationGroups)
          ..where((g) => g.personId.equals(personId) & g.deletedAt.isNull())
          ..orderBy([(g) => OrderingTerm(expression: g.createdAt)]))
        .get();

    final groups = <MedicationGroup>[];
    for (final row in rows) {
      try {
        groups.add(await _decode(row));
      } on MedicationGroupKeyMissingError {
        continue;
      }
    }
    return groups;
  }

  /// All archived groups for [personId], most-recently-archived first.
  Future<List<MedicationGroup>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.medicationGroups)
          ..where(
            (g) => g.personId.equals(personId) & g.deletedAt.isNotNull(),
          )
          ..orderBy([
            (g) => OrderingTerm(
                  expression: g.deletedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    final groups = <MedicationGroup>[];
    for (final row in rows) {
      try {
        groups.add(await _decode(row));
      } on MedicationGroupKeyMissingError {
        continue;
      }
    }
    return groups;
  }

  /// Persist updated fields. `personId` on [updated] must match the
  /// stored row — group ownership transfer is not supported (same
  /// reasoning as medications).
  Future<MedicationGroup> update(MedicationGroup updated) async {
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw MedicationGroupKeyMissingError(
        groupId: updated.id,
        personId: updated.personId,
      );
    }

    final existing = await (_db.select(_db.medicationGroups)
          ..where((g) => g.id.equals(updated.id)))
        .getSingleOrNull();
    if (existing == null) {
      throw MedicationGroupNotFoundError(updated.id);
    }
    if (existing.personId != updated.personId) {
      throw StateError(
        'MedicationGroupRepository.update refused: attempted to change '
        'personId (existing=${existing.personId}, '
        'updated=${updated.personId}). Create a new group instead.',
      );
    }

    final now = _clock().toUtc();
    final members = _normalizeMembers(updated.memberMedicationIds);
    final payload = EncryptedMedicationGroupPayload(
      schemaVersion: EncryptedMedicationGroupPayload.currentSchemaVersion,
      name: updated.name,
      schedule: updated.schedule,
      memberMedicationIds: members,
    );
    final encrypted = await _sealPayload(
      groupId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(_db.medicationGroups)
          ..where((g) => g.id.equals(updated.id)))
        .write(
      MedicationGroupsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      memberMedicationIds: members,
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  /// Archive (soft-delete) a group. A second archive on an
  /// already-archived row throws — same semantics as
  /// `MedicationRepository.archive`.
  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.medicationGroups)
          ..where((g) => g.id.equals(id) & g.deletedAt.isNull()))
        .write(
      MedicationGroupsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) {
      throw MedicationGroupNotFoundError(id);
    }
  }

  /// Un-archive a previously-archived group.
  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.medicationGroups)
          ..where((g) => g.id.equals(id) & g.deletedAt.isNotNull()))
        .write(
      MedicationGroupsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: const Value(null),
      ),
    );
    if (affected == 0) {
      throw MedicationGroupNotFoundError(id);
    }
  }

  /// Dedupe, drop empties, and freeze. A group's member order is
  /// visible in the Today screen so we preserve the caller's first
  /// occurrence of each id and drop later duplicates.
  List<String> _normalizeMembers(Iterable<String> input) {
    final seen = <String>{};
    final out = <String>[];
    for (final m in input) {
      final trimmed = m.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) out.add(trimmed);
    }
    return List.unmodifiable(out);
  }

  Future<EncryptedPayload> _sealPayload({
    required String groupId,
    required String personId,
    required EncryptedMedicationGroupPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(groupId: groupId, personId: personId),
    );
  }

  Future<MedicationGroup> _decode(MedicationGroupRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw MedicationGroupKeyMissingError(
        groupId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(groupId: row.id, personId: row.personId),
    );
    final payload = EncryptedMedicationGroupPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return MedicationGroup(
      id: row.id,
      personId: row.personId,
      name: payload.name,
      schedule: payload.schedule,
      memberMedicationIds: List.unmodifiable(payload.memberMedicationIds),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  /// AAD binds ciphertext to both groupId and personId — prevents
  /// relocation attacks where a blob is moved between groups belonging
  /// to the same Person.
  List<int> _aadFor({
    required String groupId,
    required String personId,
  }) =>
      utf8.encode('medication_group:$personId:$groupId:payload');
}

/// Application-wide [MedicationGroupRepository].
final medicationGroupRepositoryProvider =
    Provider<MedicationGroupRepository>((ref) {
  return MedicationGroupRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
