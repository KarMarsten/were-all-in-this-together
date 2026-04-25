import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/programs/data/encrypted_program_payload.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';

class ProgramKeyMissingError implements Exception {
  ProgramKeyMissingError({required this.programId, required this.personId});

  final String programId;
  final String personId;

  @override
  String toString() =>
      'ProgramKeyMissingError: no encryption key found for Person '
      '$personId while resolving program $programId';
}

class ProgramNotFoundError implements Exception {
  ProgramNotFoundError(this.programId);
  final String programId;

  @override
  String toString() => 'ProgramNotFoundError: no program with id $programId';
}

class ProgramRepository {
  ProgramRepository({
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

  Future<Program> create({
    required String personId,
    required ProgramKind kind,
    required String name,
    String? phone,
    String? contactName,
    String? contactRole,
    String? email,
    String? address,
    String? websiteUrl,
    String? hours,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    final key = await _keys.load(personId);
    if (key == null) {
      throw ProgramKeyMissingError(
        programId: '(not-yet-created)',
        personId: personId,
      );
    }
    final id = _uuid.v4();
    final now = _clock().toUtc();
    final payload = EncryptedProgramPayload(
      schemaVersion: EncryptedProgramPayload.currentSchemaVersion,
      name: name.trim(),
      phone: _nullIfBlank(phone),
      contactName: _nullIfBlank(contactName),
      contactRole: _nullIfBlank(contactRole),
      email: _nullIfBlank(email),
      address: _nullIfBlank(address),
      websiteUrl: _normalizeOptionalUrl(websiteUrl),
      hours: _nullIfBlank(hours),
      notes: _nullIfBlank(notes),
    );
    final encrypted = await _sealPayload(
      programId: id,
      personId: personId,
      payload: payload,
      key: key,
    );
    await _db.into(_db.programs).insert(
          ProgramsCompanion.insert(
            id: id,
            personId: personId,
            kind: kind.index,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );
    return Program(
      id: id,
      personId: personId,
      kind: kind,
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      phone: _nullIfBlank(phone),
      contactName: _nullIfBlank(contactName),
      contactRole: _nullIfBlank(contactRole),
      email: _nullIfBlank(email),
      address: _nullIfBlank(address),
      websiteUrl: _normalizeOptionalUrl(websiteUrl),
      hours: _nullIfBlank(hours),
      notes: _nullIfBlank(notes),
    );
  }

  Future<Program?> findById(String id) async {
    final row = await (_db.select(
      _db.programs,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  Future<List<Program>> listActiveForPerson(String personId) async {
    final rows = await (_db.select(_db.programs)
          ..where(
            (p) => p.personId.equals(personId) & p.deletedAt.isNull(),
          )
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  Future<List<Program>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.programs)
          ..where(
            (p) => p.personId.equals(personId) & p.deletedAt.isNotNull(),
          )
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.deletedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  Future<Program> update(Program updated) async {
    if (updated.name.trim().isEmpty) {
      throw ArgumentError.value(updated.name, 'name', 'must not be empty');
    }
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw ProgramKeyMissingError(
        programId: updated.id,
        personId: updated.personId,
      );
    }
    final existing = await (_db.select(
      _db.programs,
    )..where((p) => p.id.equals(updated.id))).getSingleOrNull();
    if (existing == null) throw ProgramNotFoundError(updated.id);
    if (existing.personId != updated.personId) {
      throw StateError('ProgramRepository.update refused: personId mismatch.');
    }
    final now = _clock().toUtc();
    final payload = EncryptedProgramPayload(
      schemaVersion: EncryptedProgramPayload.currentSchemaVersion,
      name: updated.name.trim(),
      phone: _nullIfBlank(updated.phone),
      contactName: _nullIfBlank(updated.contactName),
      contactRole: _nullIfBlank(updated.contactRole),
      email: _nullIfBlank(updated.email),
      address: _nullIfBlank(updated.address),
      websiteUrl: _normalizeOptionalUrl(updated.websiteUrl),
      hours: _nullIfBlank(updated.hours),
      notes: _nullIfBlank(updated.notes),
    );
    final encrypted = await _sealPayload(
      programId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );
    await (_db.update(_db.programs)..where((p) => p.id.equals(updated.id)))
        .write(
      ProgramsCompanion(
        kind: Value(updated.kind.index),
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );
    return updated.copyWith(
      name: updated.name.trim(),
      phone: _nullIfBlank(updated.phone),
      contactName: _nullIfBlank(updated.contactName),
      contactRole: _nullIfBlank(updated.contactRole),
      email: _nullIfBlank(updated.email),
      address: _nullIfBlank(updated.address),
      websiteUrl: _normalizeOptionalUrl(updated.websiteUrl),
      hours: _nullIfBlank(updated.hours),
      notes: _nullIfBlank(updated.notes),
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.programs)
          ..where((p) => p.id.equals(id) & p.deletedAt.isNull()))
        .write(
      ProgramsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) throw ProgramNotFoundError(id);
  }

  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.programs)
          ..where((p) => p.id.equals(id) & p.deletedAt.isNotNull()))
        .write(
      ProgramsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: const Value(null),
      ),
    );
    if (affected == 0) throw ProgramNotFoundError(id);
  }

  static String? _nullIfBlank(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static String? _normalizeOptionalUrl(String? raw) {
    final trimmed = _nullIfBlank(raw);
    if (trimmed == null) return null;
    return normalizeUserUrl(trimmed);
  }

  static String normalizeUserUrl(String raw) {
    final trimmed = raw.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) return trimmed;
    return 'https://$trimmed';
  }

  Future<List<Program>> _decodeMany(List<ProgramRow> rows) async {
    final out = <Program>[];
    for (final row in rows) {
      try {
        out.add(await _decode(row));
      } on ProgramKeyMissingError {
        continue;
      }
    }
    return out;
  }

  Future<EncryptedPayload> _sealPayload({
    required String programId,
    required String personId,
    required EncryptedProgramPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(programId: programId, personId: personId),
    );
  }

  Future<Program> _decode(ProgramRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw ProgramKeyMissingError(programId: row.id, personId: row.personId);
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(programId: row.id, personId: row.personId),
    );
    final payload = EncryptedProgramPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return Program(
      id: row.id,
      personId: row.personId,
      kind: _kindFromIndex(row.kind),
      name: payload.name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      phone: payload.phone,
      contactName: payload.contactName,
      contactRole: payload.contactRole,
      email: payload.email,
      address: payload.address,
      websiteUrl: payload.websiteUrl,
      hours: payload.hours,
      notes: payload.notes,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  ProgramKind _kindFromIndex(int index) {
    if (index < 0 || index >= ProgramKind.values.length) {
      return ProgramKind.other;
    }
    return ProgramKind.values[index];
  }

  List<int> _aadFor({
    required String programId,
    required String personId,
  }) =>
      utf8.encode('program:$personId:$programId:payload');
}

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
