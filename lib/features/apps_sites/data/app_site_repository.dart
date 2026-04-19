import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/apps_sites/data/encrypted_app_site_payload.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';

class AppSiteKeyMissingError implements Exception {
  AppSiteKeyMissingError({required this.appSiteId, required this.personId});

  final String appSiteId;
  final String personId;

  @override
  String toString() =>
      'AppSiteKeyMissingError: no encryption key found for Person '
      '$personId while resolving app site $appSiteId';
}

class AppSiteNotFoundError implements Exception {
  AppSiteNotFoundError(this.appSiteId);
  final String appSiteId;

  @override
  String toString() =>
      'AppSiteNotFoundError: no app site with id $appSiteId';
}

class AppSiteRepository {
  AppSiteRepository({
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

  Future<AppSite> create({
    required String personId,
    required String title,
    required String url,
    String? notes,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    final normalized = normalizeUserUrl(url);
    final key = await _keys.load(personId);
    if (key == null) {
      throw AppSiteKeyMissingError(
        appSiteId: '(not-yet-created)',
        personId: personId,
      );
    }
    final id = _uuid.v4();
    final now = _clock().toUtc();
    final payload = EncryptedAppSitePayload(
      schemaVersion: EncryptedAppSitePayload.currentSchemaVersion,
      title: title.trim(),
      url: normalized,
      notes: _nullIfBlank(notes),
    );
    final encrypted = await _sealPayload(
      appSiteId: id,
      personId: personId,
      payload: payload,
      key: key,
    );
    await _db.into(_db.appSites).insert(
          AppSitesCompanion.insert(
            id: id,
            personId: personId,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );
    return AppSite(
      id: id,
      personId: personId,
      title: title.trim(),
      url: normalized,
      createdAt: now,
      updatedAt: now,
      notes: _nullIfBlank(notes),
    );
  }

  Future<AppSite?> findById(String id) async {
    final row = await (_db.select(
      _db.appSites,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  Future<List<AppSite>> listActiveForPerson(String personId) async {
    final rows = await (_db.select(_db.appSites)
          ..where(
            (a) => a.personId.equals(personId) & a.deletedAt.isNull(),
          )
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return _decodeMany(rows);
  }

  Future<List<AppSite>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.appSites)
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

  Future<AppSite> update(AppSite updated) async {
    if (updated.title.trim().isEmpty) {
      throw ArgumentError.value(updated.title, 'title', 'must not be empty');
    }
    final normalized = normalizeUserUrl(updated.url);
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw AppSiteKeyMissingError(
        appSiteId: updated.id,
        personId: updated.personId,
      );
    }
    final existing = await (_db.select(
      _db.appSites,
    )..where((a) => a.id.equals(updated.id))).getSingleOrNull();
    if (existing == null) throw AppSiteNotFoundError(updated.id);
    if (existing.personId != updated.personId) {
      throw StateError('AppSiteRepository.update refused: personId mismatch.');
    }
    final now = _clock().toUtc();
    final payload = EncryptedAppSitePayload(
      schemaVersion: EncryptedAppSitePayload.currentSchemaVersion,
      title: updated.title.trim(),
      url: normalized,
      notes: _nullIfBlank(updated.notes),
    );
    final encrypted = await _sealPayload(
      appSiteId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );
    await (_db.update(_db.appSites)..where((a) => a.id.equals(updated.id)))
        .write(
      AppSitesCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );
    return updated.copyWith(
      title: updated.title.trim(),
      url: normalized,
      notes: _nullIfBlank(updated.notes),
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.appSites)
          ..where((a) => a.id.equals(id) & a.deletedAt.isNull()))
        .write(
      AppSitesCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) throw AppSiteNotFoundError(id);
  }

  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.appSites)
          ..where((a) => a.id.equals(id) & a.deletedAt.isNotNull()))
        .write(
      AppSitesCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: const Value(null),
      ),
    );
    if (affected == 0) throw AppSiteNotFoundError(id);
  }

  /// Ensures [raw] has an http/https scheme for storage and launching.
  static String normalizeUserUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(raw, 'url', 'must not be empty');
    }
    final u = Uri.tryParse(t);
    if (u != null &&
        u.hasScheme &&
        (u.scheme == 'http' || u.scheme == 'https')) {
      return t;
    }
    return 'https://$t';
  }

  static String? _nullIfBlank(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<List<AppSite>> _decodeMany(List<AppSiteRow> rows) async {
    final out = <AppSite>[];
    for (final row in rows) {
      try {
        out.add(await _decode(row));
      } on AppSiteKeyMissingError {
        continue;
      }
    }
    return out;
  }

  Future<EncryptedPayload> _sealPayload({
    required String appSiteId,
    required String personId,
    required EncryptedAppSitePayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(appSiteId: appSiteId, personId: personId),
    );
  }

  Future<AppSite> _decode(AppSiteRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw AppSiteKeyMissingError(appSiteId: row.id, personId: row.personId);
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(appSiteId: row.id, personId: row.personId),
    );
    final payload = EncryptedAppSitePayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return AppSite(
      id: row.id,
      personId: row.personId,
      title: payload.title,
      url: payload.url,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      notes: payload.notes,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      rowVersion: row.rowVersion,
      lastWriterDeviceId: row.lastWriterDeviceId,
      keyVersion: row.keyVersion,
    );
  }

  List<int> _aadFor({
    required String appSiteId,
    required String personId,
  }) =>
      utf8.encode('appSite:$personId:$appSiteId:payload');
}

final appSiteRepositoryProvider = Provider<AppSiteRepository>((ref) {
  return AppSiteRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
