import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/appointments/data/encrypted_appointment_payload.dart';
import 'package:were_all_in_this_together/features/appointments/domain/appointment.dart';

/// Thrown when an appointment row exists for a Person but that
/// Person's encryption key is missing on this device. Same
/// data-integrity meaning as `PersonKeyMissingError`.
class AppointmentKeyMissingError implements Exception {
  AppointmentKeyMissingError({
    required this.appointmentId,
    required this.personId,
  });

  final String appointmentId;
  final String personId;

  @override
  String toString() =>
      'AppointmentKeyMissingError: no encryption key found for Person '
      '$personId while resolving appointment $appointmentId';
}

/// Thrown on writes that reference an id that doesn't exist.
class AppointmentNotFoundError implements Exception {
  AppointmentNotFoundError(this.appointmentId);

  final String appointmentId;

  @override
  String toString() =>
      'AppointmentNotFoundError: no appointment with id $appointmentId';
}

/// Repository for `Appointment`.
///
/// Encrypts sensitive fields under the owning Person's key. AAD
/// binds each ciphertext to both the appointment id and the Person
/// id, so a blob cannot be relocated between rows.
///
/// `scheduledAt` is intentionally stored in plaintext on the row
/// (see the `Appointments` table doc): it's the sort key for the
/// upcoming / past split and the fire-time for Phase 2's background
/// reminder scheduler, which shouldn't need to decrypt a whole
/// roster just to know *when* to fire.
///
/// Soft-delete ("archive" in UI copy) preserves rows for Phase 2
/// sync tombstones. `archive` + `restore` are the only public
/// mutations that change the deletion state.
class AppointmentRepository {
  AppointmentRepository({
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

  /// Create a new appointment for [personId].
  ///
  /// We look up the Person's key *first*, so if the caller passes
  /// an id we have no key for we fail before writing a row we
  /// could never read.
  Future<Appointment> create({
    required String personId,
    required String title,
    required DateTime scheduledAt,
    String? providerId,
    String? location,
    int? durationMinutes,
    String? notes,
    int? reminderLeadMinutes,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (durationMinutes != null && durationMinutes <= 0) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'must be positive',
      );
    }
    if (reminderLeadMinutes != null && reminderLeadMinutes < 0) {
      throw ArgumentError.value(
        reminderLeadMinutes,
        'reminderLeadMinutes',
        'must be non-negative',
      );
    }

    final key = await _keys.load(personId);
    if (key == null) {
      throw AppointmentKeyMissingError(
        appointmentId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final scheduledUtc = scheduledAt.toUtc();
    final payload = EncryptedAppointmentPayload(
      schemaVersion: EncryptedAppointmentPayload.currentSchemaVersion,
      title: title,
      providerId: providerId,
      location: location,
      durationMinutes: durationMinutes,
      notes: notes,
      reminderLeadMinutes: reminderLeadMinutes,
    );
    final encrypted = await _sealPayload(
      appointmentId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db.into(_db.appointments).insert(
          AppointmentsCompanion.insert(
            id: id,
            personId: personId,
            scheduledAt: scheduledUtc.millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return Appointment(
      id: id,
      personId: personId,
      title: title,
      scheduledAt: scheduledUtc,
      providerId: providerId,
      location: location,
      durationMinutes: durationMinutes,
      notes: notes,
      reminderLeadMinutes: reminderLeadMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Look up a single appointment by id.
  ///
  /// Returns `null` for unknown ids. Looks at both active and
  /// archived rows on purpose — edit / history flows need to
  /// resolve archived appointments too.
  Future<Appointment?> findById(String id) async {
    final row = await (_db.select(_db.appointments)
          ..where((a) => a.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  /// Active (non-archived) appointments for [personId] whose
  /// [Appointment.scheduledAt] is on or after [now], soonest first.
  ///
  /// Callers who want "today" filter the result — keeping the
  /// semantics at "upcoming" here (rather than "today") means
  /// a single query covers the list screen, the dashboard card,
  /// and future notification scheduling. [now] defaults to the
  /// repo clock so tests can pin time without a wall-clock race.
  Future<List<Appointment>> listUpcomingForPerson(
    String personId, {
    DateTime? now,
  }) async {
    final cutoff = (now ?? _clock()).toUtc().millisecondsSinceEpoch;
    final rows = await (_db.select(_db.appointments)
          ..where(
            (a) =>
                a.personId.equals(personId) &
                a.deletedAt.isNull() &
                a.scheduledAt.isBiggerOrEqualValue(cutoff),
          )
          ..orderBy([(a) => OrderingTerm(expression: a.scheduledAt)]))
        .get();
    return _decodeMany(rows);
  }

  /// Active (non-archived) appointments for [personId] whose
  /// [Appointment.scheduledAt] is strictly before [now], most
  /// recent first.
  Future<List<Appointment>> listPastForPerson(
    String personId, {
    DateTime? now,
  }) async {
    final cutoff = (now ?? _clock()).toUtc().millisecondsSinceEpoch;
    final rows = await (_db.select(_db.appointments)
          ..where(
            (a) =>
                a.personId.equals(personId) &
                a.deletedAt.isNull() &
                a.scheduledAt.isSmallerThanValue(cutoff),
          )
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.scheduledAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  /// Non-archived appointments for [personId] whose
  /// [Appointment.scheduledAt] falls in `[fromInclusive, toExclusive)`,
  /// in chronological order.
  ///
  /// Exists so the Today screen can pull both past-today and
  /// upcoming-today entries in a single query without reaching for
  /// [listUpcomingForPerson] + [listPastForPerson] and re-merging in
  /// Dart. Both endpoints are UTC — callers converting from a local
  /// calendar day should call `.toUtc()` themselves.
  Future<List<Appointment>> listForPersonInRange({
    required String personId,
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final fromMs = fromInclusive.toUtc().millisecondsSinceEpoch;
    final toMs = toExclusive.toUtc().millisecondsSinceEpoch;
    final rows = await (_db.select(_db.appointments)
          ..where(
            (a) =>
                a.personId.equals(personId) &
                a.deletedAt.isNull() &
                a.scheduledAt.isBiggerOrEqualValue(fromMs) &
                a.scheduledAt.isSmallerThanValue(toMs),
          )
          ..orderBy([(a) => OrderingTerm(expression: a.scheduledAt)]))
        .get();
    return _decodeMany(rows);
  }

  /// All archived appointments for [personId], newest-archived
  /// first.
  Future<List<Appointment>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.appointments)
          ..where(
            (a) => a.personId.equals(personId) & a.deletedAt.isNotNull(),
          )
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.deletedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  /// Persist updated fields. Bumps `rowVersion` and stamps
  /// `updatedAt`. `personId` on [updated] must match the stored
  /// row's personId — ownership transfer is not supported.
  Future<Appointment> update(Appointment updated) async {
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw AppointmentKeyMissingError(
        appointmentId: updated.id,
        personId: updated.personId,
      );
    }

    final existing = await (_db.select(_db.appointments)
          ..where((a) => a.id.equals(updated.id)))
        .getSingleOrNull();
    if (existing == null) {
      throw AppointmentNotFoundError(updated.id);
    }
    if (existing.personId != updated.personId) {
      throw StateError(
        'AppointmentRepository.update refused: attempted to change '
        'personId (existing=${existing.personId}, '
        'updated=${updated.personId}). Create a new Appointment instead.',
      );
    }

    final now = _clock().toUtc();
    final scheduledUtc = updated.scheduledAt.toUtc();
    final payload = EncryptedAppointmentPayload(
      schemaVersion: EncryptedAppointmentPayload.currentSchemaVersion,
      title: updated.title,
      providerId: updated.providerId,
      location: updated.location,
      durationMinutes: updated.durationMinutes,
      notes: updated.notes,
      reminderLeadMinutes: updated.reminderLeadMinutes,
    );
    final encrypted = await _sealPayload(
      appointmentId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(_db.appointments)
          ..where((a) => a.id.equals(updated.id)))
        .write(
      AppointmentsCompanion(
        scheduledAt: Value(scheduledUtc.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      scheduledAt: scheduledUtc,
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  /// Archive (soft-delete) an appointment. Throws on a second
  /// archive of an already-archived row, mirroring the other
  /// repositories.
  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.appointments)
          ..where((a) => a.id.equals(id) & a.deletedAt.isNull()))
        .write(
      AppointmentsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) {
      throw AppointmentNotFoundError(id);
    }
  }

  /// Un-archive a previously archived appointment. Throws if the
  /// row isn't archived — callers should check before asking.
  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.appointments)
          ..where((a) => a.id.equals(id) & a.deletedAt.isNotNull()))
        .write(
      AppointmentsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: const Value(null),
      ),
    );
    if (affected == 0) {
      throw AppointmentNotFoundError(id);
    }
  }

  Future<List<Appointment>> _decodeMany(List<AppointmentRow> rows) async {
    final out = <Appointment>[];
    for (final row in rows) {
      try {
        out.add(await _decode(row));
      } on AppointmentKeyMissingError {
        // Key not on this device yet (Phase 2 sync arrival-order
        // race); skip rather than fail the whole list.
        continue;
      }
    }
    return out;
  }

  Future<EncryptedPayload> _sealPayload({
    required String appointmentId,
    required String personId,
    required EncryptedAppointmentPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(appointmentId: appointmentId, personId: personId),
    );
  }

  Future<Appointment> _decode(AppointmentRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw AppointmentKeyMissingError(
        appointmentId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(appointmentId: row.id, personId: row.personId),
    );
    final payload = EncryptedAppointmentPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return Appointment(
      id: row.id,
      personId: row.personId,
      title: payload.title,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        row.scheduledAt,
        isUtc: true,
      ),
      providerId: payload.providerId,
      location: payload.location,
      durationMinutes: payload.durationMinutes,
      notes: payload.notes,
      reminderLeadMinutes: payload.reminderLeadMinutes,
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

  /// AAD binds a ciphertext to both its row id and its owning
  /// Person. Without personId an attacker could relocate an
  /// appointment blob between rows belonging to the same Person;
  /// without appointmentId, between any two rows.
  List<int> _aadFor({
    required String appointmentId,
    required String personId,
  }) =>
      utf8.encode('appointment:$personId:$appointmentId:payload');
}

/// Application-wide [AppointmentRepository].
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
