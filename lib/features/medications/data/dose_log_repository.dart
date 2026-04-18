import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/encrypted_dose_log_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';

/// Thrown when a dose log's row exists but the owning Person's
/// encryption key is missing on this device. Same meaning as the
/// equivalent errors on the People / Medications repos.
class DoseLogKeyMissingError implements Exception {
  DoseLogKeyMissingError({required this.doseLogId, required this.personId});

  final String doseLogId;
  final String personId;

  @override
  String toString() =>
      'DoseLogKeyMissingError: no encryption key for Person $personId '
      'while resolving dose log $doseLogId';
}

/// Repository for dose logs. Pairs with [DoseLog] in the domain layer.
///
/// Encryption posture:
///
/// * Payload sealed under the owning Person's key (same key as the
///   owning medication).
/// * AAD binds to `(doseLogId, personId, medicationId, scheduledAt)`
///   so a log blob can't be relocated between meds, persons, or time
///   slots — and the server-side ciphertext is useless without those
///   four plaintext values anyway.
///
/// Upsert semantics: [record] inserts on first call and replaces on
/// subsequent calls for the same `(medicationId, scheduledAt)` pair.
/// The DB enforces `UNIQUE(medicationId, scheduledAtUtcMs)`.
class DoseLogRepository {
  DoseLogRepository({
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

  /// Record that the user marked a specific scheduled dose.
  ///
  /// If a log already exists for `(medicationId, scheduledAt)`, its
  /// outcome and note are updated in-place and `rowVersion` is bumped.
  /// Otherwise a new row is written.
  ///
  /// Passing an all-whitespace [note] stores `null` — the UI should
  /// feel free to write the value of a text field straight through.
  Future<DoseLog> record({
    required String personId,
    required String medicationId,
    required DateTime scheduledAt,
    required DoseOutcome outcome,
    String? note,
  }) async {
    final key = await _keys.load(personId);
    if (key == null) {
      throw DoseLogKeyMissingError(
        doseLogId: '(not-yet-created)',
        personId: personId,
      );
    }

    final normalizedNote =
        (note == null || note.trim().isEmpty) ? null : note.trim();
    final scheduledUtc = scheduledAt.toUtc();
    final now = _clock().toUtc();

    final existing = await _findBySchedule(
      medicationId: medicationId,
      scheduledAtUtcMs: scheduledUtc.millisecondsSinceEpoch,
    );

    final payload = EncryptedDoseLogPayload(
      schemaVersion: EncryptedDoseLogPayload.currentSchemaVersion,
      outcome: outcome,
      loggedAt: now,
      note: normalizedNote,
    );

    if (existing != null) {
      final encrypted = await _sealPayload(
        doseLogId: existing.id,
        personId: personId,
        medicationId: medicationId,
        scheduledAtUtcMs: scheduledUtc.millisecondsSinceEpoch,
        payload: payload,
        key: key,
      );
      await (_db.update(_db.doseLogs)
            ..where((l) => l.id.equals(existing.id)))
          .write(
        DoseLogsCompanion(
          updatedAt: Value(now.millisecondsSinceEpoch),
          rowVersion: Value(existing.rowVersion + 1),
          // Clear the tombstone on re-record: if a user undoes a log
          // and then re-records it, resurrection is the obvious
          // intent.
          deletedAt: const Value(null),
          payload: Value(encrypted.toBytes()),
        ),
      );
      return (await _decodeById(existing.id))!;
    }

    final id = _uuid.v4();
    final encrypted = await _sealPayload(
      doseLogId: id,
      personId: personId,
      medicationId: medicationId,
      scheduledAtUtcMs: scheduledUtc.millisecondsSinceEpoch,
      payload: payload,
      key: key,
    );

    await _db.into(_db.doseLogs).insert(
          DoseLogsCompanion.insert(
            id: id,
            personId: personId,
            medicationId: medicationId,
            scheduledAtUtcMs: scheduledUtc.millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return DoseLog(
      id: id,
      personId: personId,
      medicationId: medicationId,
      scheduledAt: scheduledUtc,
      loggedAt: now,
      outcome: outcome,
      note: normalizedNote,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Mark a previously-recorded log as undone (soft-delete). Idempotent:
  /// calling on a not-present or already-undone log is a no-op.
  Future<void> undo({
    required String medicationId,
    required DateTime scheduledAt,
  }) async {
    final now = _clock().toUtc();
    final scheduledUtc = scheduledAt.toUtc();

    await (_db.update(_db.doseLogs)
          ..where(
            (l) =>
                l.medicationId.equals(medicationId) &
                l.scheduledAtUtcMs
                    .equals(scheduledUtc.millisecondsSinceEpoch) &
                l.deletedAt.isNull(),
          ))
        .write(
      DoseLogsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  /// Every non-tombstoned log whose `scheduledAt` falls in
  /// `[fromInclusive, toExclusive)` for any of [medicationIds].
  ///
  /// Empty `medicationIds` short-circuits to an empty list — the
  /// caller is almost certainly rendering an empty Today screen and
  /// there's nothing to query.
  Future<List<DoseLog>> forMedicationsInRange({
    required Iterable<String> medicationIds,
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final ids = medicationIds.toList();
    if (ids.isEmpty) return const <DoseLog>[];

    final rows = await (_db.select(_db.doseLogs)
          ..where(
            (l) =>
                l.medicationId.isIn(ids) &
                l.scheduledAtUtcMs.isBetweenValues(
                  fromInclusive.toUtc().millisecondsSinceEpoch,
                  // `isBetweenValues` is inclusive on the upper bound,
                  // so subtract 1ms to match the half-open window we
                  // advertise.
                  toExclusive.toUtc().millisecondsSinceEpoch - 1,
                ) &
                l.deletedAt.isNull(),
          )
          ..orderBy([(l) => OrderingTerm(expression: l.scheduledAtUtcMs)]))
        .get();

    final result = <DoseLog>[];
    for (final row in rows) {
      try {
        result.add(await _decode(row));
      } on DoseLogKeyMissingError {
        continue;
      }
    }
    return result;
  }

  Future<DoseLogRow?> _findBySchedule({
    required String medicationId,
    required int scheduledAtUtcMs,
  }) async {
    return (_db.select(_db.doseLogs)
          ..where(
            (l) =>
                l.medicationId.equals(medicationId) &
                l.scheduledAtUtcMs.equals(scheduledAtUtcMs),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DoseLog?> _decodeById(String id) async {
    final row = await (_db.select(_db.doseLogs)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  Future<EncryptedPayload> _sealPayload({
    required String doseLogId,
    required String personId,
    required String medicationId,
    required int scheduledAtUtcMs,
    required EncryptedDoseLogPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(
        doseLogId: doseLogId,
        personId: personId,
        medicationId: medicationId,
        scheduledAtUtcMs: scheduledAtUtcMs,
      ),
    );
  }

  Future<DoseLog> _decode(DoseLogRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw DoseLogKeyMissingError(
        doseLogId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(
        doseLogId: row.id,
        personId: row.personId,
        medicationId: row.medicationId,
        scheduledAtUtcMs: row.scheduledAtUtcMs,
      ),
    );
    final payload = EncryptedDoseLogPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return DoseLog(
      id: row.id,
      personId: row.personId,
      medicationId: row.medicationId,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        row.scheduledAtUtcMs,
        isUtc: true,
      ),
      loggedAt: payload.loggedAt,
      outcome: payload.outcome,
      note: payload.note,
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

  /// AAD binds a ciphertext to its dose log id, owning Person,
  /// medication, *and* the scheduled time. Scheduled time in
  /// particular matters: without it an attacker with DB access could
  /// shuffle logs between time slots for the same med to make it look
  /// like a missed dose was taken.
  List<int> _aadFor({
    required String doseLogId,
    required String personId,
    required String medicationId,
    required int scheduledAtUtcMs,
  }) =>
      utf8.encode(
        'doselog:$personId:$medicationId:$scheduledAtUtcMs:$doseLogId:payload',
      );
}

/// Application-wide [DoseLogRepository].
final doseLogRepositoryProvider = Provider<DoseLogRepository>((ref) {
  return DoseLogRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
