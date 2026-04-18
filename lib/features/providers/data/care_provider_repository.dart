import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:were_all_in_this_together/core/crypto/crypto_service.dart';
import 'package:were_all_in_this_together/core/crypto/encrypted_payload.dart';
import 'package:were_all_in_this_together/core/crypto/key_storage.dart';
import 'package:were_all_in_this_together/core/database/app_database.dart';
import 'package:were_all_in_this_together/features/providers/data/encrypted_care_provider_payload.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';

/// Thrown when a care-provider row exists for a Person but that Person's
/// encryption key is missing on this device. Same data-integrity meaning
/// as `PersonKeyMissingError` / `MedicationKeyMissingError`.
class CareProviderKeyMissingError implements Exception {
  CareProviderKeyMissingError({
    required this.careProviderId,
    required this.personId,
  });

  final String careProviderId;
  final String personId;

  @override
  String toString() =>
      'CareProviderKeyMissingError: no encryption key found for Person '
      '$personId while resolving care provider $careProviderId';
}

/// Thrown on writes that reference an id that doesn't exist.
class CareProviderNotFoundError implements Exception {
  CareProviderNotFoundError(this.careProviderId);

  final String careProviderId;

  @override
  String toString() =>
      'CareProviderNotFoundError: no care provider with id $careProviderId';
}

/// Repository for `CareProvider`.
///
/// Encrypts sensitive fields under the owning Person's key. AAD binds
/// each ciphertext to *both* the care-provider id and the Person id,
/// so the DB cannot be tampered with by relocating a blob between rows.
///
/// Soft-delete ("archive" in UI copy) preserves rows for Phase 2 sync
/// tombstones and so archived providers can still be referenced from
/// historical medications / appointments. `archive` + `restore` are
/// the only public mutations that change the deletion state.
class CareProviderRepository {
  CareProviderRepository({
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

  /// Create a new care provider for [personId].
  ///
  /// We look up the Person's key *first*, so if the caller passes an id
  /// we have no key for we fail before writing a row we could never
  /// read.
  Future<CareProvider> create({
    required String personId,
    required String name,
    required CareProviderKind kind,
    String? specialty,
    String? phone,
    String? address,
    String? portalUrl,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }

    final key = await _keys.load(personId);
    if (key == null) {
      throw CareProviderKeyMissingError(
        careProviderId: '(not-yet-created)',
        personId: personId,
      );
    }

    final id = _uuid.v4();
    final now = _clock().toUtc();
    final payload = EncryptedCareProviderPayload(
      schemaVersion: EncryptedCareProviderPayload.currentSchemaVersion,
      name: name,
      kind: kind,
      specialty: specialty,
      phone: phone,
      address: address,
      portalUrl: portalUrl,
      notes: notes,
    );
    final encrypted = await _sealPayload(
      careProviderId: id,
      personId: personId,
      payload: payload,
      key: key,
    );

    await _db.into(_db.careProviders).insert(
          CareProvidersCompanion.insert(
            id: id,
            personId: personId,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            payload: encrypted.toBytes(),
          ),
        );

    return CareProvider(
      id: id,
      personId: personId,
      name: name,
      kind: kind,
      specialty: specialty,
      phone: phone,
      address: address,
      portalUrl: portalUrl,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Look up a single care provider by id.
  ///
  /// Returns `null` for unknown ids. Looks at both active and archived
  /// rows on purpose: callers holding a `prescriberId` on a medication
  /// (future PR) or a `providerId` on an appointment (future feature)
  /// must be able to resolve the provider even after it's been
  /// archived, so that historical references still render.
  Future<CareProvider?> findById(String id) async {
    final row = await (_db.select(_db.careProviders)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _decode(row);
  }

  /// All active (non-archived) care providers for [personId], oldest
  /// first.
  ///
  /// Rows whose key is missing are skipped (mirroring `listActive` on
  /// `PersonRepository`).
  Future<List<CareProvider>> listActiveForPerson(String personId) async {
    final rows = await (_db.select(_db.careProviders)
          ..where((p) => p.personId.equals(personId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();

    final providers = <CareProvider>[];
    for (final row in rows) {
      try {
        providers.add(await _decode(row));
      } on CareProviderKeyMissingError {
        continue;
      }
    }
    return providers;
  }

  /// All archived care providers for [personId], newest-archived first.
  Future<List<CareProvider>> listArchivedForPerson(String personId) async {
    final rows = await (_db.select(_db.careProviders)
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

    final providers = <CareProvider>[];
    for (final row in rows) {
      try {
        providers.add(await _decode(row));
      } on CareProviderKeyMissingError {
        continue;
      }
    }
    return providers;
  }

  /// Persist updated sensitive fields. Bumps `rowVersion` and stamps
  /// `updatedAt`. `personId` on [updated] must match the stored row's
  /// personId — ownership transfer is not supported.
  Future<CareProvider> update(CareProvider updated) async {
    final key = await _keys.load(updated.personId);
    if (key == null) {
      throw CareProviderKeyMissingError(
        careProviderId: updated.id,
        personId: updated.personId,
      );
    }

    final existing = await (_db.select(_db.careProviders)
          ..where((p) => p.id.equals(updated.id)))
        .getSingleOrNull();
    if (existing == null) {
      throw CareProviderNotFoundError(updated.id);
    }
    if (existing.personId != updated.personId) {
      throw StateError(
        'CareProviderRepository.update refused: attempted to change '
        'personId (existing=${existing.personId}, '
        'updated=${updated.personId}). Create a new CareProvider instead.',
      );
    }

    final now = _clock().toUtc();
    final payload = EncryptedCareProviderPayload(
      schemaVersion: EncryptedCareProviderPayload.currentSchemaVersion,
      name: updated.name,
      kind: updated.kind,
      specialty: updated.specialty,
      phone: updated.phone,
      address: updated.address,
      portalUrl: updated.portalUrl,
      notes: updated.notes,
    );
    final encrypted = await _sealPayload(
      careProviderId: updated.id,
      personId: updated.personId,
      payload: payload,
      key: key,
    );

    await (_db.update(_db.careProviders)
          ..where((p) => p.id.equals(updated.id)))
        .write(
      CareProvidersCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        rowVersion: Value(updated.rowVersion + 1),
        payload: Value(encrypted.toBytes()),
      ),
    );

    return updated.copyWith(
      updatedAt: now,
      rowVersion: updated.rowVersion + 1,
    );
  }

  /// Archive (soft-delete) a care provider. Throws on a second archive
  /// of an already-archived row, mirroring `MedicationRepository`.
  Future<void> archive(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.careProviders)
          ..where((p) => p.id.equals(id) & p.deletedAt.isNull()))
        .write(
      CareProvidersCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (affected == 0) {
      throw CareProviderNotFoundError(id);
    }
  }

  /// Un-archive a previously archived care provider. Throws if the row
  /// is not archived — callers should check before asking.
  Future<void> restore(String id) async {
    final now = _clock().toUtc();
    final affected = await (_db.update(_db.careProviders)
          ..where((p) => p.id.equals(id) & p.deletedAt.isNotNull()))
        .write(
      CareProvidersCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        deletedAt: const Value(null),
      ),
    );
    if (affected == 0) {
      throw CareProviderNotFoundError(id);
    }
  }

  Future<EncryptedPayload> _sealPayload({
    required String careProviderId,
    required String personId,
    required EncryptedCareProviderPayload payload,
    required SecretKey key,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    return _crypto.encrypt(
      bytes,
      key: key,
      aad: _aadFor(careProviderId: careProviderId, personId: personId),
    );
  }

  Future<CareProvider> _decode(CareProviderRow row) async {
    final key = await _keys.load(row.personId);
    if (key == null) {
      throw CareProviderKeyMissingError(
        careProviderId: row.id,
        personId: row.personId,
      );
    }
    final encrypted = EncryptedPayload.fromBytes(row.payload);
    final plaintext = await _crypto.decrypt(
      encrypted,
      key: key,
      aad: _aadFor(careProviderId: row.id, personId: row.personId),
    );
    final payload = EncryptedCareProviderPayload.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
    return CareProvider(
      id: row.id,
      personId: row.personId,
      name: payload.name,
      kind: payload.kind,
      specialty: payload.specialty,
      phone: payload.phone,
      address: payload.address,
      portalUrl: payload.portalUrl,
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

  /// AAD binds a ciphertext to both its row id and its owning Person.
  /// Without personId an attacker could relocate a provider blob
  /// between rows belonging to the *same* Person; without
  /// careProviderId, between any two rows.
  List<int> _aadFor({
    required String careProviderId,
    required String personId,
  }) =>
      utf8.encode('careProvider:$personId:$careProviderId:payload');
}

/// Application-wide [CareProviderRepository].
final careProviderRepositoryProvider = Provider<CareProviderRepository>((ref) {
  return CareProviderRepository(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    keys: ref.watch(keyStorageProvider),
  );
});
