import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/medications/data/encrypted_medication_event_payload.dart';
import 'package:were_all_in_this_together/features/medications/domain/medication_event.dart';

/// Thrown when a medication-event row exists for a Person but that
/// Person's encryption key is missing on this device. Same data-
/// integrity meaning as `PersonKeyMissingError`.
class MedicationEventKeyMissingError implements Exception {
  MedicationEventKeyMissingError({
    required this.eventId,
    required this.personId,
  });

  final String eventId;
  final String personId;

  @override
  String toString() =>
      'MedicationEventKeyMissingError: no encryption key found for Person '
      '$personId while resolving medication event $eventId';
}

/// Thrown on writes that reference an event id that doesn't exist.
class MedicationEventNotFoundError implements Exception {
  MedicationEventNotFoundError(this.eventId);

  final String eventId;

  @override
  String toString() =>
      'MedicationEventNotFoundError: no medication event with id $eventId';
}

/// Repository for `MedicationEvent` — the append-only timeline of
/// regimen changes per medication.
///
/// Separate from `MedicationRepository` on purpose: the two can be
/// reasoned about independently, the event store is append-mostly
/// (create + archive, no in-place update), and tests for the
/// auto-logging flow stay focused.
///
/// AAD scopes every ciphertext to its own id *and* the owning
/// Person's id, matching the convention used everywhere else.
class MedicationEventRepository {
  MedicationEventRepository({
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

  /// Append a new event to a medication's timeline.
  ///
  /// [occurredAt] defaults to "now" for auto-logged events. Manual
  /// backfill flows (future PR) supply a historical date. We don't
  /// validate it against [DateTime.now] — a caregiver recording a
  /// regimen change "as of tomorrow" is legitimate.
  Future<MedicationEvent> create({
    required String medicationId,
    required String personId,
    required MedicationEventKind kind,
    DateTime? occurredAt,
    List<MedicationFieldDiff> diffs = const [],
    String? note,
  }) async {
    final key = await _keys.load(personId);
    if (key == null) {
      throw MedicationEventKeyMissingError(
        eventId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final resolvedOccurredAt = (occurredAt ?? now).toUtc();

    final payload = EncryptedMedicationEventPayload(
      schemaVersion: EncryptedMedicationEventPayload.currentSchemaVersion,
      kind: kind,
      note: note,
      diffs: diffs,
    );
    final encrypted = await _sealPayload(
      eventId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db.into(_db.medicationEvents).insert(
          MedicationEventsCompanion.insert(
            id: id,
            medicationId: medicationId,
            personId: personId,
            occurredAt: resolvedOccurredAt.millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return MedicationEvent(
      id: id,
      medicationId: medicationId,
      personId: personId,
      kind: kind,
      occurredAt: resolvedOccurredAt,
      createdAt: now,
      updatedAt: now,
      diffs: List.unmodifiable(diffs),
      note: note,
    );
  }

  /// List events for a medication, most-recent first.
  ///
  /// Ordering is by [MedicationEvent.occurredAt] descending, tied-
  /// broken by [MedicationEvent.createdAt] — two backfills entered
  /// the same day for different historical dates sort by when they
  /// happened in the patient's timeline, and two auto-logs stamped
  /// at the same millisecond fall back to insertion order.
  /// Archived events are excluded.
  Future<List<MedicationEvent>> listForMedication(String medicationId) async {
    final rows = await (_db.select(_db.medicationEvents)
          ..where(
            (e) =>
                e.medicationId.equals(medicationId) & e.deletedAt.isNull(),
          )
          ..orderBy([
            (e) => OrderingTerm(
                  expression: e.occurredAt,
                  mode: OrderingMode.desc,
                ),
            (e) => OrderingTerm(
                  expression: e.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    final events = <MedicationEvent>[];
    for (final row in rows) {
      try {
        events.add(await _decode(row));
      } on MedicationEventKeyMissingError {
        continue;
      }
    }
    return events;
  }

  /// Archive (soft-delete) a single event. Used to correct a mis-
  /// logged event without losing it. Throws if the event is missing
  /// or already archived, matching the pattern on
  /// `MedicationRepository.archive`.
  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.medicationEvents)
          ..where((e) => e.id.equals(id) & e.deletedAt.isNull()))
        .write(
      MedicationEventsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) {
      throw MedicationEventNotFoundError(id);
    }
  }

  Future<EncryptedPayload> _sealPayload({
    required String eventId,
    required String personId,
    required EncryptedMedicationEventPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(eventId: eventId, personId: personId),
    );
  }

  Future<MedicationEvent> _decode(MedicationEventRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw MedicationEventKeyMissingError(
        eventId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(eventId: row.id, personId: row.personId),
    );
    final payload = EncryptedMedicationEventPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return MedicationEvent(
      id: row.id,
      medicationId: row.medicationId,
      personId: row.personId,
      kind: payload.kind,
      occurredAt:
          DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      diffs: payload.diffs,
      note: payload.note,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  /// AAD binds a ciphertext to both its event id and the owning
  /// Person. Scoping to event id (not medication id) is deliberate:
  /// relocating an event blob between events on the *same*
  /// medication would still be tampering, and tying to the event id
  /// catches that.
  List<int> _aadFor({
    required String eventId,
    required String personId,
  }) =>
      utf8.encode('medicationEvent:$personId:$eventId:payload');
}

/// Application-wide [MedicationEventRepository].
final medicationEventRepositoryProvider =
    Provider<MedicationEventRepository>((ref) {
  return MedicationEventRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
