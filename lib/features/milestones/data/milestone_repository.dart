import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/milestones/data/encrypted_milestone_payload.dart';
import 'package:were_all_in_this_together/features/milestones/domain/milestone.dart';

/// Thrown when a milestone row exists for a Person but that
/// Person's encryption key is missing on this device. Same
/// data-integrity meaning as `AppointmentKeyMissingError` /
/// `PersonKeyMissingError`.
class MilestoneKeyMissingError implements Exception {
  MilestoneKeyMissingError({
    required this.milestoneId,
    required this.personId,
  });

  final String milestoneId;
  final String personId;

  @override
  String toString() =>
      'MilestoneKeyMissingError: no encryption key found for Person '
      '$personId while resolving milestone $milestoneId';
}

/// Thrown on writes that reference an id that doesn't exist.
class MilestoneNotFoundError implements Exception {
  MilestoneNotFoundError(this.milestoneId);

  final String milestoneId;

  @override
  String toString() =>
      'MilestoneNotFoundError: no milestone with id $milestoneId';
}

/// Repository for `Milestone`.
///
/// Encrypts sensitive fields (`title`, `notes`) under the owning
/// Person's key. AAD binds each ciphertext to both the milestone
/// id and the Person id, so a blob cannot be relocated between
/// rows.
///
/// `occurredAt`, `precision`, `kind`, `providerId` are plaintext
/// on the row — they're the sort key, grouping key, and future
/// search filters. See the `Milestones` table doc for the
/// leakage analysis.
///
/// Soft-delete ("archive" in UI copy) preserves rows for Phase 2
/// sync tombstones. `archive` + `restore` are the only public
/// mutations that change the deletion state.
class MilestoneRepository {
  MilestoneRepository({
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

  /// Create a new milestone for [personId].
  ///
  /// `occurredAt` is canonicalised by [precision] before storage
  /// (year → Jan 1 UTC, month → the 1st UTC, day → midnight UTC,
  /// exact → as-is). This keeps every row's sort key honest and
  /// frees callers from having to pre-round.
  Future<Milestone> create({
    required String personId,
    required MilestoneKind kind,
    required String title,
    required DateTime occurredAt,
    required MilestonePrecision precision,
    String? providerId,
    String? notes,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }

    final key = await _keys.load(personId);
    if (key == null) {
      throw MilestoneKeyMissingError(
        milestoneId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final canonical = canonicaliseOccurredAt(occurredAt, precision);
    final payload = EncryptedMilestonePayload(
      schemaVersion: EncryptedMilestonePayload.currentSchemaVersion,
      title: title,
      notes: notes,
    );
    final encrypted = await _sealPayload(
      milestoneId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db.into(_db.milestones).insert(
          MilestonesCompanion.insert(
            id: id,
            personId: personId,
            occurredAt: canonical.millisecondsSinceEpoch,
            precision: precision.index,
            kind: kind.index,
            providerId: Value(providerId),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return Milestone(
      id: id,
      personId: personId,
      kind: kind,
      title: title,
      occurredAt: canonical,
      precision: precision,
      providerId: providerId,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Look up a single milestone by id. Returns `null` for unknown
  /// ids. Looks at both active and archived rows on purpose —
  /// edit / deep-link flows need to resolve archived milestones
  /// too.
  Future<Milestone?> findById(String id) async {
    final row = await (_db.select(_db.milestones)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  /// Non-archived milestones for [personId], most recent first.
  ///
  /// Descending by `occurredAt` matches the natural "history"
  /// reading order — newest entries first, scroll down into older
  /// memories.
  Future<List<Milestone>> listActiveForPerson(String personId) async {
    final rows = await (_db.select(_db.milestones)
          ..where(
            (m) => m.personId.equals(personId) & m.deletedAt.isNull(),
          )
          ..orderBy([
            (m) => OrderingTerm(
                  expression: m.occurredAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  /// All archived milestones for [personId], newest-archived
  /// first.
  Future<List<Milestone>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.milestones)
          ..where(
            (m) => m.personId.equals(personId) & m.deletedAt.isNotNull(),
          )
          ..orderBy([
            (m) => OrderingTerm(
                  expression: m.deletedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  /// Persist updated fields. Bumps `rowVersion`, stamps
  /// `updatedAt`, and re-canonicalises `occurredAt` against the
  /// updated `precision`. `personId` on [updated] must match the
  /// stored row's personId — ownership transfer is not supported.
  Future<Milestone> update(Milestone updated) async {
    if (updated.title.trim().isEmpty) {
      throw ArgumentError.value(updated.title, 'title', 'must not be empty');
    }

    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw MilestoneKeyMissingError(
        milestoneId: updated.id,
        personId: updated.personId,
      );
    }

    final existing = await (_db.select(_db.milestones)
          ..where((m) => m.id.equals(updated.id)))
        .getSingleOrNull();
    if (existing == null) {
      throw MilestoneNotFoundError(updated.id);
    }
    if (existing.personId != updated.personId) {
      throw StateError(
        'MilestoneRepository.update refused: attempted to change '
        'personId (existing=${existing.personId}, '
        'updated=${updated.personId}). Create a new Milestone instead.',
      );
    }

    final now = _clock().toUtc();
    final canonical =
        canonicaliseOccurredAt(updated.occurredAt, updated.precision);
    final payload = EncryptedMilestonePayload(
      schemaVersion: EncryptedMilestonePayload.currentSchemaVersion,
      title: updated.title,
      notes: updated.notes,
    );
    final encrypted = await _sealPayload(
      milestoneId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(_db.milestones)
          ..where((m) => m.id.equals(updated.id)))
        .write(
      MilestonesCompanion(
        occurredAt: Value(canonical.millisecondsSinceEpoch),
        precision: Value(updated.precision.index),
        kind: Value(updated.kind.index),
        providerId: Value(updated.providerId),
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      occurredAt: canonical,
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  /// Archive (soft-delete) a milestone. Throws on a second archive
  /// of an already-archived row, mirroring the other repositories.
  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.milestones)
          ..where((m) => m.id.equals(id) & m.deletedAt.isNull()))
        .write(
      MilestonesCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) {
      throw MilestoneNotFoundError(id);
    }
  }

  /// Un-archive a previously archived milestone. Throws if the
  /// row isn't archived — callers should check before asking.
  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.milestones)
          ..where((m) => m.id.equals(id) & m.deletedAt.isNotNull()))
        .write(
      MilestonesCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: const Value(null),
      ),
    );
    if (affected == 0) {
      throw MilestoneNotFoundError(id);
    }
  }

  Future<List<Milestone>> _decodeMany(List<MilestoneRow> rows) async {
    final out = <Milestone>[];
    for (final row in rows) {
      try {
        out.add(await _decode(row));
      } on MilestoneKeyMissingError {
        // Key not on this device yet (Phase 2 sync arrival-order
        // race); skip rather than fail the whole list.
        continue;
      }
    }
    return out;
  }

  Future<EncryptedPayload> _sealPayload({
    required String milestoneId,
    required String personId,
    required EncryptedMilestonePayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(milestoneId: milestoneId, personId: personId),
    );
  }

  Future<Milestone> _decode(MilestoneRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw MilestoneKeyMissingError(
        milestoneId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(milestoneId: row.id, personId: row.personId),
    );
    final payload = EncryptedMilestonePayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return Milestone(
      id: row.id,
      personId: row.personId,
      kind: _kindFromIndex(row.kind),
      title: payload.title,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row.occurredAt,
        isUtc: true,
      ),
      precision: _precisionFromIndex(row.precision),
      providerId: row.providerId,
      notes: payload.notes,
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

  /// Forward-compatible decode: an index from a newer build
  /// collapses to `other` so older clients still render
  /// something rather than crash. Matches the "append-only enum"
  /// policy in the table doc.
  MilestoneKind _kindFromIndex(int index) {
    if (index < 0 || index >= MilestoneKind.values.length) {
      return MilestoneKind.other;
    }
    return MilestoneKind.values[index];
  }

  /// Forward-compatible decode: an unknown precision index
  /// collapses to the coarsest known tier so the UI still renders.
  MilestonePrecision _precisionFromIndex(int index) {
    if (index < 0 || index >= MilestonePrecision.values.length) {
      return MilestonePrecision.year;
    }
    return MilestonePrecision.values[index];
  }

  /// AAD binds a ciphertext to both its row id and its owning
  /// Person. Without personId an attacker could relocate a
  /// milestone blob between rows belonging to the same Person;
  /// without milestoneId, between any two rows.
  List<int> _aadFor({
    required String milestoneId,
    required String personId,
  }) =>
      utf8.encode('milestone:$personId:$milestoneId:payload');
}

/// Application-wide [MilestoneRepository].
final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  return MilestoneRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
