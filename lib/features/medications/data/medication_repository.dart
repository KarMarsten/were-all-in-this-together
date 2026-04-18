import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/encrypted_medication_payload.dart';
import 'package:were_all_in_this_together/features/medications/data/medication_event_repository.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_diff.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_schedule.dart';

/// Thrown when a medication row exists for a Person but that Person's
/// encryption key is missing on this device. Same data-integrity meaning
/// as `PersonKeyMissingError`.
class MedicationKeyMissingError implements Exception {
  MedicationKeyMissingError({
    required this.medicationId,
    required this.personId,
  });

  final String medicationId;
  final String personId;

  @override
  String toString() =>
      'MedicationKeyMissingError: no encryption key found for Person '
      '$personId while resolving medication $medicationId';
}

/// Thrown on writes that reference a medication id that doesn't exist
/// (deleted concurrently, typoed, etc.).
class MedicationNotFoundError implements Exception {
  MedicationNotFoundError(this.medicationId);

  final String medicationId;

  @override
  String toString() =>
      'MedicationNotFoundError: no medication with id $medicationId';
}

/// Repository for Medications.
///
/// Encrypts sensitive fields under the owning Person's key. AAD binds
/// each ciphertext to *both* the medication id and the Person id, so the
/// DB cannot be tampered with by relocating a blob between rows — even
/// between meds belonging to the same Person.
///
/// Soft-delete ("archive" in UI copy) preserves rows for Phase 2 sync
/// tombstones and to allow restore. `archive` + `restore` are the only
/// public mutations that change the deletion state.
class MedicationRepository {
  MedicationRepository({
    required AppDatabase database,
    required CryptoService crypto,
    required KeyStorage keys,
    required MedicationEventRepository events,
    Uuid? uuidGenerator,
    DateTime Function()? clock,
  })  : _db = database,
        _crypto = crypto,
        _keys = keys,
        _events = events,
        _uuid = uuidGenerator ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final CryptoService _crypto;
  final KeyStorage _keys;
  final MedicationEventRepository _events;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Create a new medication for [personId].
  ///
  /// We look up the Person's key *first*, so that if the caller somehow
  /// passes an id we have no key for (e.g. a soft-deleted Person whose
  /// key was wiped), we fail before writing a row we can never read.
  Future<Medication> create({
    required String personId,
    required String name,
    String? dose,
    MedicationForm? form,
    String? prescriber,
    String? prescriberId,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    MedicationSchedule schedule = MedicationSchedule.asNeeded,
    int? nagIntervalMinutesOverride,
    int? nagCapOverride,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }

    final key = await _keys.load(personId);
    if (key == null) {
      // Use the Person-style error here: from the caller's perspective,
      // the problem is the Person doesn't have a key on this device.
      throw MedicationKeyMissingError(
        medicationId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final payload = EncryptedMedicationPayload(
      schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
      name: name,
      dose: dose,
      form: form,
      prescriber: prescriber,
      prescriberId: prescriberId,
      notes: notes,
      startDate: startDate,
      endDate: endDate,
      schedule: schedule,
      nagIntervalMinutesOverride: nagIntervalMinutesOverride,
      nagCapOverride: nagCapOverride,
    );
    final encrypted = await _sealPayload(
      medicationId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    // Both writes go in a single transaction: a medication without
    // its initial `created` event would be a silently lossy timeline,
    // and an orphaned event without its medication would be worse.
    await _db.transaction(() async {
      await _db.into(_db.medications).insert(
            MedicationsCompanion.insert(
              id: id,
              personId: personId,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              payload: encrypted.toBytes(),
            ),
          );
      await _events.create(
        medicationId: id,
        personId: personId,
        kind: MedicationEventKind.created,
        occurredAt: now,
      );
    });

    return Medication(
      id: id,
      personId: personId,
      name: name,
      dose: dose,
      form: form,
      prescriber: prescriber,
      prescriberId: prescriberId,
      notes: notes,
      startDate: startDate,
      endDate: endDate,
      schedule: schedule,
      nagIntervalMinutesOverride: nagIntervalMinutesOverride,
      nagCapOverride: nagCapOverride,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Look up a single medication by id.
  ///
  /// Returns `null` for unknown ids and for archived (soft-deleted) rows —
  /// callers wanting archived rows must use [listArchivedForPerson].
  Future<Medication?> findById(String id) async {
    final row = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(id) & m.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  /// All active (non-archived) medications for [personId], oldest first.
  ///
  /// Rows whose key is missing are skipped (mirroring `listActive` on
  /// `PersonRepository`): a single missing key should not hide every
  /// other med. Other decode failures propagate.
  Future<List<Medication>> listActiveForPerson(String personId) async {
    final rows = await (_db.select(_db.medications)
          ..where((m) => m.personId.equals(personId) & m.deletedAt.isNull())
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt)]))
        .get();

    final meds = <Medication>[];
    for (final row in rows) {
      try {
        meds.add(await _decode(row));
      } on MedicationKeyMissingError {
        continue;
      }
    }
    return meds;
  }

  /// All archived medications for [personId], newest-archived first.
  ///
  /// Provided so a future "Archived" section in settings can render them
  /// for restore. Archived rows with missing keys are also skipped.
  Future<List<Medication>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.medications)
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

    final meds = <Medication>[];
    for (final row in rows) {
      try {
        meds.add(await _decode(row));
      } on MedicationKeyMissingError {
        continue;
      }
    }
    return meds;
  }

  /// Persist updated sensitive fields. Bumps `rowVersion` and stamps
  /// `updatedAt`. `personId` on [updated] must match the stored row's
  /// personId — ownership transfer is not supported.
  Future<Medication> update(Medication updated) async {
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw MedicationKeyMissingError(
        medicationId: updated.id,
        personId: updated.personId,
      );
    }

    final existing = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(updated.id)))
        .getSingleOrNull();
    if (existing == null) {
      throw MedicationNotFoundError(updated.id);
    }
    if (existing.personId != updated.personId) {
      throw StateError(
        'MedicationRepository.update refused: attempted to change '
        'personId (existing=${existing.personId}, '
        'updated=${updated.personId}). Create a new Medication instead.',
      );
    }

    // Decode the pre-update state so we can diff against the new
    // one. Failures here are fatal — silently skipping diff
    // generation would drop history without telling anyone.
    final previous = await _decode(existing);
    final diffs = diffMedicationFields(before: previous, after: updated);

    final now = _clock().toUtc();
    final payload = EncryptedMedicationPayload(
      schemaVersion: EncryptedMedicationPayload.currentSchemaVersion,
      name: updated.name,
      dose: updated.dose,
      form: updated.form,
      prescriber: updated.prescriber,
      prescriberId: updated.prescriberId,
      notes: updated.notes,
      startDate: updated.startDate,
      endDate: updated.endDate,
      schedule: updated.schedule,
      nagIntervalMinutesOverride: updated.nagIntervalMinutesOverride,
      nagCapOverride: updated.nagCapOverride,
    );
    final encrypted = await _sealPayload(
      medicationId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await _db.transaction(() async {
      await (_db.update(_db.medications)
            ..where((m) => m.id.equals(updated.id)))
          .write(
        MedicationsCompanion(
          updatedAt: Value(now.millisecondsSinceEpoch),
          rowVersion: Value(updated.rowVersion + 1),
          payload: Value(encrypted.toBytes()),
        ),
      );
      // Only emit an event when something medically-meaningful
      // changed — a save that only touched notes / reminder
      // overrides / nothing at all should leave the timeline quiet.
      // See `diffMedicationFields` for the exact field list.
      if (diffs.isNotEmpty) {
        await _events.create(
          medicationId: updated.id,
          personId: updated.personId,
          kind: MedicationEventKind.fieldsChanged,
          occurredAt: now,
          diffs: diffs,
        );
      }
    });

    return updated.copyWith(
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  /// Archive (soft-delete) a medication. Idempotent-unfriendly: a second
  /// archive on an already-archived row throws, matching
  /// `PersonRepository.softDelete`'s semantics.
  ///
  /// Also appends an [MedicationEventKind.archived] event to the
  /// medication's history so a later restore shows the complete
  /// arc ("archived on X, restored on Y").
  Future<void> archive(String id) async {
    // Load first to grab the personId — the archive event is scoped
    // to the owning Person for AAD, and loading also lets us throw
    // the caller-expected NotFound early rather than after partial
    // writes.
    final existing = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(id) & m.deletedAt.isNull()))
        .getSingleOrNull();
    if (existing == null) {
      throw MedicationNotFoundError(id);
    }

    final now = _clock().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.medications)
            ..where((m) => m.id.equals(id) & m.deletedAt.isNull()))
          .write(
        MedicationsCompanion(
          updatedAt: Value(now.millisecondsSinceEpoch),
          deletedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      await _events.create(
        medicationId: id,
        personId: existing.personId,
        kind: MedicationEventKind.archived,
        occurredAt: now,
      );
    });
  }

  /// Un-archive a previously archived medication. Throws if the row is
  /// not archived — callers should check before asking.
  ///
  /// Appends an [MedicationEventKind.restored] event to the
  /// medication's history for symmetry with [archive].
  Future<void> restore(String id) async {
    final existing = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(id) & m.deletedAt.isNotNull()))
        .getSingleOrNull();
    if (existing == null) {
      throw MedicationNotFoundError(id);
    }

    final now = _clock().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.medications)
            ..where((m) => m.id.equals(id) & m.deletedAt.isNotNull()))
          .write(
        MedicationsCompanion(
          updatedAt: Value(now.millisecondsSinceEpoch),
          deletedAt: const Value(null),
        ),
      );
      await _events.create(
        medicationId: id,
        personId: existing.personId,
        kind: MedicationEventKind.restored,
        occurredAt: now,
      );
    });
  }

  Future<EncryptedPayload> _sealPayload({
    required String medicationId,
    required String personId,
    required EncryptedMedicationPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(medicationId: medicationId, personId: personId),
    );
  }

  Future<Medication> _decode(MedicationRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw MedicationKeyMissingError(
        medicationId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(medicationId: row.id, personId: row.personId),
    );
    final payload = EncryptedMedicationPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return Medication(
      id: row.id,
      personId: row.personId,
      name: payload.name,
      dose: payload.dose,
      form: payload.form,
      prescriber: payload.prescriber,
      prescriberId: payload.prescriberId,
      notes: payload.notes,
      startDate: payload.startDate,
      endDate: payload.endDate,
      schedule: payload.schedule,
      nagIntervalMinutesOverride: payload.nagIntervalMinutesOverride,
      nagCapOverride: payload.nagCapOverride,
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

  /// AAD binds a ciphertext to both its row id and its owning Person.
  /// Without personId an attacker could relocate a med blob between
  /// rows belonging to the *same* Person; without medicationId, between
  /// any two rows.
  List<int> _aadFor({
    required String medicationId,
    required String personId,
  }) =>
      utf8.encode('medication:$personId:$medicationId:payload');
}

/// Application-wide [MedicationRepository].
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
    events: ref.watch(medicationEventRepositoryProvider),
  );
});
