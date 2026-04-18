// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PersonsTable extends Persons with TableInfo<$PersonsTable, PersonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWriterDeviceIdMeta =
      const VerificationMeta('lastWriterDeviceId');
  @override
  late final GeneratedColumn<String> lastWriterDeviceId =
      GeneratedColumn<String>(
        'last_writer_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyVersionMeta = const VerificationMeta(
    'keyVersion',
  );
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
    'key_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('last_writer_device_id')) {
      context.handle(
        _lastWriterDeviceIdMeta,
        lastWriterDeviceId.isAcceptableOrUnknown(
          data['last_writer_device_id']!,
          _lastWriterDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('key_version')) {
      context.handle(
        _keyVersionMeta,
        keyVersion.isAcceptableOrUnknown(data['key_version']!, _keyVersionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      lastWriterDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_writer_device_id'],
      ),
      keyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class PersonRow extends DataClass implements Insertable<PersonRow> {
  /// Client-generated UUID v4.
  final String id;

  /// Epoch milliseconds.
  final int createdAt;

  /// Epoch milliseconds.
  final int updatedAt;

  /// Epoch milliseconds; `null` means not deleted. Soft-delete only — we
  /// never physically delete rows in Phase 1 so sync can reconcile
  /// tombstones in Phase 2.
  final int? deletedAt;

  /// Monotonically increasing per-row counter, incremented on every write.
  final int rowVersion;

  /// Identifier of the device that last wrote this row. `null` in Phase 1
  /// (single device); populated in Phase 2.
  final String? lastWriterDeviceId;

  /// Which key generation decrypted this row's payload. Incremented on key
  /// rotation; during rotation some rows may carry the old version until
  /// they're rewritten.
  final int keyVersion;

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  final Uint8List payload;
  const PersonRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.rowVersion,
    this.lastWriterDeviceId,
    required this.keyVersion,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['row_version'] = Variable<int>(rowVersion);
    if (!nullToAbsent || lastWriterDeviceId != null) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId);
    }
    map['key_version'] = Variable<int>(keyVersion);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rowVersion: Value(rowVersion),
      lastWriterDeviceId: lastWriterDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWriterDeviceId),
      keyVersion: Value(keyVersion),
      payload: Value(payload),
    );
  }

  factory PersonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      lastWriterDeviceId: serializer.fromJson<String?>(
        json['lastWriterDeviceId'],
      ),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'lastWriterDeviceId': serializer.toJson<String?>(lastWriterDeviceId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  PersonRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? rowVersion,
    Value<String?> lastWriterDeviceId = const Value.absent(),
    int? keyVersion,
    Uint8List? payload,
  }) => PersonRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rowVersion: rowVersion ?? this.rowVersion,
    lastWriterDeviceId: lastWriterDeviceId.present
        ? lastWriterDeviceId.value
        : this.lastWriterDeviceId,
    keyVersion: keyVersion ?? this.keyVersion,
    payload: payload ?? this.payload,
  );
  PersonRow copyWithCompanion(PersonsCompanion data) {
    return PersonRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      lastWriterDeviceId: data.lastWriterDeviceId.present
          ? data.lastWriterDeviceId.value
          : this.lastWriterDeviceId,
      keyVersion: data.keyVersion.present
          ? data.keyVersion.value
          : this.keyVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.rowVersion == this.rowVersion &&
          other.lastWriterDeviceId == this.lastWriterDeviceId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class PersonsCompanion extends UpdateCompanion<PersonRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowVersion;
  final Value<String?> lastWriterDeviceId;
  final Value<int> keyVersion;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<PersonRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowVersion,
    Expression<String>? lastWriterDeviceId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowVersion != null) 'row_version': rowVersion,
      if (lastWriterDeviceId != null)
        'last_writer_device_id': lastWriterDeviceId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowVersion,
    Value<String?>? lastWriterDeviceId,
    Value<int>? keyVersion,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return PersonsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowVersion: rowVersion ?? this.rowVersion,
      lastWriterDeviceId: lastWriterDeviceId ?? this.lastWriterDeviceId,
      keyVersion: keyVersion ?? this.keyVersion,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (lastWriterDeviceId.present) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, MedicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWriterDeviceIdMeta =
      const VerificationMeta('lastWriterDeviceId');
  @override
  late final GeneratedColumn<String> lastWriterDeviceId =
      GeneratedColumn<String>(
        'last_writer_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyVersionMeta = const VerificationMeta(
    'keyVersion',
  );
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
    'key_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('last_writer_device_id')) {
      context.handle(
        _lastWriterDeviceIdMeta,
        lastWriterDeviceId.isAcceptableOrUnknown(
          data['last_writer_device_id']!,
          _lastWriterDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('key_version')) {
      context.handle(
        _keyVersionMeta,
        keyVersion.isAcceptableOrUnknown(data['key_version']!, _keyVersionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      lastWriterDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_writer_device_id'],
      ),
      keyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class MedicationRow extends DataClass implements Insertable<MedicationRow> {
  /// Client-generated UUID v4.
  final String id;

  /// Owning Person's id. Not a declared SQL foreign key — see class docs.
  final String personId;

  /// Epoch milliseconds.
  final int createdAt;

  /// Epoch milliseconds.
  final int updatedAt;

  /// Epoch milliseconds; `null` means not deleted. Soft-delete only.
  final int? deletedAt;

  /// Monotonically increasing per-row counter, incremented on every write.
  final int rowVersion;

  /// Identifier of the device that last wrote this row. `null` in Phase 1
  /// (single device); populated in Phase 2.
  final String? lastWriterDeviceId;

  /// Which key generation decrypted this row's payload.
  final int keyVersion;

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  final Uint8List payload;
  const MedicationRow({
    required this.id,
    required this.personId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.rowVersion,
    this.lastWriterDeviceId,
    required this.keyVersion,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['row_version'] = Variable<int>(rowVersion);
    if (!nullToAbsent || lastWriterDeviceId != null) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId);
    }
    map['key_version'] = Variable<int>(keyVersion);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      personId: Value(personId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rowVersion: Value(rowVersion),
      lastWriterDeviceId: lastWriterDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWriterDeviceId),
      keyVersion: Value(keyVersion),
      payload: Value(payload),
    );
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      lastWriterDeviceId: serializer.fromJson<String?>(
        json['lastWriterDeviceId'],
      ),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'lastWriterDeviceId': serializer.toJson<String?>(lastWriterDeviceId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  MedicationRow copyWith({
    String? id,
    String? personId,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? rowVersion,
    Value<String?> lastWriterDeviceId = const Value.absent(),
    int? keyVersion,
    Uint8List? payload,
  }) => MedicationRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rowVersion: rowVersion ?? this.rowVersion,
    lastWriterDeviceId: lastWriterDeviceId.present
        ? lastWriterDeviceId.value
        : this.lastWriterDeviceId,
    keyVersion: keyVersion ?? this.keyVersion,
    payload: payload ?? this.payload,
  );
  MedicationRow copyWithCompanion(MedicationsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      lastWriterDeviceId: data.lastWriterDeviceId.present
          ? data.lastWriterDeviceId.value
          : this.lastWriterDeviceId,
      keyVersion: data.keyVersion.present
          ? data.keyVersion.value
          : this.keyVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.rowVersion == this.rowVersion &&
          other.lastWriterDeviceId == this.lastWriterDeviceId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class MedicationsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowVersion;
  final Value<String?> lastWriterDeviceId;
  final Value<int> keyVersion;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String personId,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<MedicationRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowVersion,
    Expression<String>? lastWriterDeviceId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowVersion != null) 'row_version': rowVersion,
      if (lastWriterDeviceId != null)
        'last_writer_device_id': lastWriterDeviceId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowVersion,
    Value<String?>? lastWriterDeviceId,
    Value<int>? keyVersion,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowVersion: rowVersion ?? this.rowVersion,
      lastWriterDeviceId: lastWriterDeviceId ?? this.lastWriterDeviceId,
      keyVersion: keyVersion ?? this.keyVersion,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (lastWriterDeviceId.present) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoseLogsTable extends DoseLogs
    with TableInfo<$DoseLogsTable, DoseLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtUtcMsMeta = const VerificationMeta(
    'scheduledAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> scheduledAtUtcMs = GeneratedColumn<int>(
    'scheduled_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWriterDeviceIdMeta =
      const VerificationMeta('lastWriterDeviceId');
  @override
  late final GeneratedColumn<String> lastWriterDeviceId =
      GeneratedColumn<String>(
        'last_writer_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyVersionMeta = const VerificationMeta(
    'keyVersion',
  );
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
    'key_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    medicationId,
    scheduledAtUtcMs,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoseLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('scheduled_at_utc_ms')) {
      context.handle(
        _scheduledAtUtcMsMeta,
        scheduledAtUtcMs.isAcceptableOrUnknown(
          data['scheduled_at_utc_ms']!,
          _scheduledAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtUtcMsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('last_writer_device_id')) {
      context.handle(
        _lastWriterDeviceIdMeta,
        lastWriterDeviceId.isAcceptableOrUnknown(
          data['last_writer_device_id']!,
          _lastWriterDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('key_version')) {
      context.handle(
        _keyVersionMeta,
        keyVersion.isAcceptableOrUnknown(data['key_version']!, _keyVersionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {medicationId, scheduledAtUtcMs},
  ];
  @override
  DoseLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduledAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_at_utc_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      lastWriterDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_writer_device_id'],
      ),
      keyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $DoseLogsTable createAlias(String alias) {
    return $DoseLogsTable(attachedDatabase, alias);
  }
}

class DoseLogRow extends DataClass implements Insertable<DoseLogRow> {
  /// Client-generated UUID v4.
  final String id;

  /// Owning Person's id. Not a declared SQL foreign key — same
  /// rationale as on `Medications` (Phase 2 arrival order).
  final String personId;

  /// The medication this log is for. Same rationale as `personId` for
  /// not declaring a SQL FK.
  final String medicationId;

  /// When this specific scheduled dose was due, in UTC milliseconds.
  /// Part of the log's composite identity together with `medicationId`.
  final int scheduledAtUtcMs;

  /// Epoch milliseconds; when the row was first written.
  final int createdAt;

  /// Epoch milliseconds; updated on every upsert (e.g. user switches
  /// an existing Taken log to Skipped).
  final int updatedAt;

  /// Epoch milliseconds; `null` unless the log was un-done. Using a
  /// tombstone rather than a `DELETE` keeps the Phase 2 sync story
  /// symmetric with every other table.
  final int? deletedAt;

  /// Monotonically increasing per-row counter, incremented on every
  /// write. Same semantics as on `Medications`.
  final int rowVersion;

  /// Identifier of the device that last wrote this row. `null` in
  /// Phase 1 (single device); populated in Phase 2.
  final String? lastWriterDeviceId;

  /// Which key generation decrypted this row's payload.
  final int keyVersion;

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  final Uint8List payload;
  const DoseLogRow({
    required this.id,
    required this.personId,
    required this.medicationId,
    required this.scheduledAtUtcMs,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.rowVersion,
    this.lastWriterDeviceId,
    required this.keyVersion,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['medication_id'] = Variable<String>(medicationId);
    map['scheduled_at_utc_ms'] = Variable<int>(scheduledAtUtcMs);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['row_version'] = Variable<int>(rowVersion);
    if (!nullToAbsent || lastWriterDeviceId != null) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId);
    }
    map['key_version'] = Variable<int>(keyVersion);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  DoseLogsCompanion toCompanion(bool nullToAbsent) {
    return DoseLogsCompanion(
      id: Value(id),
      personId: Value(personId),
      medicationId: Value(medicationId),
      scheduledAtUtcMs: Value(scheduledAtUtcMs),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rowVersion: Value(rowVersion),
      lastWriterDeviceId: lastWriterDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWriterDeviceId),
      keyVersion: Value(keyVersion),
      payload: Value(payload),
    );
  }

  factory DoseLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseLogRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      scheduledAtUtcMs: serializer.fromJson<int>(json['scheduledAtUtcMs']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      lastWriterDeviceId: serializer.fromJson<String?>(
        json['lastWriterDeviceId'],
      ),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'medicationId': serializer.toJson<String>(medicationId),
      'scheduledAtUtcMs': serializer.toJson<int>(scheduledAtUtcMs),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'lastWriterDeviceId': serializer.toJson<String?>(lastWriterDeviceId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  DoseLogRow copyWith({
    String? id,
    String? personId,
    String? medicationId,
    int? scheduledAtUtcMs,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? rowVersion,
    Value<String?> lastWriterDeviceId = const Value.absent(),
    int? keyVersion,
    Uint8List? payload,
  }) => DoseLogRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    medicationId: medicationId ?? this.medicationId,
    scheduledAtUtcMs: scheduledAtUtcMs ?? this.scheduledAtUtcMs,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rowVersion: rowVersion ?? this.rowVersion,
    lastWriterDeviceId: lastWriterDeviceId.present
        ? lastWriterDeviceId.value
        : this.lastWriterDeviceId,
    keyVersion: keyVersion ?? this.keyVersion,
    payload: payload ?? this.payload,
  );
  DoseLogRow copyWithCompanion(DoseLogsCompanion data) {
    return DoseLogRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduledAtUtcMs: data.scheduledAtUtcMs.present
          ? data.scheduledAtUtcMs.value
          : this.scheduledAtUtcMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      lastWriterDeviceId: data.lastWriterDeviceId.present
          ? data.lastWriterDeviceId.value
          : this.lastWriterDeviceId,
      keyVersion: data.keyVersion.present
          ? data.keyVersion.value
          : this.keyVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseLogRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAtUtcMs: $scheduledAtUtcMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    medicationId,
    scheduledAtUtcMs,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseLogRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.medicationId == this.medicationId &&
          other.scheduledAtUtcMs == this.scheduledAtUtcMs &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.rowVersion == this.rowVersion &&
          other.lastWriterDeviceId == this.lastWriterDeviceId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class DoseLogsCompanion extends UpdateCompanion<DoseLogRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> medicationId;
  final Value<int> scheduledAtUtcMs;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowVersion;
  final Value<String?> lastWriterDeviceId;
  final Value<int> keyVersion;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const DoseLogsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduledAtUtcMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoseLogsCompanion.insert({
    required String id,
    required String personId,
    required String medicationId,
    required int scheduledAtUtcMs,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       medicationId = Value(medicationId),
       scheduledAtUtcMs = Value(scheduledAtUtcMs),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<DoseLogRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? medicationId,
    Expression<int>? scheduledAtUtcMs,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowVersion,
    Expression<String>? lastWriterDeviceId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduledAtUtcMs != null) 'scheduled_at_utc_ms': scheduledAtUtcMs,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowVersion != null) 'row_version': rowVersion,
      if (lastWriterDeviceId != null)
        'last_writer_device_id': lastWriterDeviceId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoseLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? medicationId,
    Value<int>? scheduledAtUtcMs,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowVersion,
    Value<String?>? lastWriterDeviceId,
    Value<int>? keyVersion,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return DoseLogsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      medicationId: medicationId ?? this.medicationId,
      scheduledAtUtcMs: scheduledAtUtcMs ?? this.scheduledAtUtcMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowVersion: rowVersion ?? this.rowVersion,
      lastWriterDeviceId: lastWriterDeviceId ?? this.lastWriterDeviceId,
      keyVersion: keyVersion ?? this.keyVersion,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (scheduledAtUtcMs.present) {
      map['scheduled_at_utc_ms'] = Variable<int>(scheduledAtUtcMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (lastWriterDeviceId.present) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseLogsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAtUtcMs: $scheduledAtUtcMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationGroupsTable extends MedicationGroups
    with TableInfo<$MedicationGroupsTable, MedicationGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWriterDeviceIdMeta =
      const VerificationMeta('lastWriterDeviceId');
  @override
  late final GeneratedColumn<String> lastWriterDeviceId =
      GeneratedColumn<String>(
        'last_writer_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyVersionMeta = const VerificationMeta(
    'keyVersion',
  );
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
    'key_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('last_writer_device_id')) {
      context.handle(
        _lastWriterDeviceIdMeta,
        lastWriterDeviceId.isAcceptableOrUnknown(
          data['last_writer_device_id']!,
          _lastWriterDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('key_version')) {
      context.handle(
        _keyVersionMeta,
        keyVersion.isAcceptableOrUnknown(data['key_version']!, _keyVersionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      lastWriterDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_writer_device_id'],
      ),
      keyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $MedicationGroupsTable createAlias(String alias) {
    return $MedicationGroupsTable(attachedDatabase, alias);
  }
}

class MedicationGroupRow extends DataClass
    implements Insertable<MedicationGroupRow> {
  /// Client-generated UUID v4.
  final String id;

  /// Owning Person. Not a declared SQL foreign key — same Phase 2
  /// arrival-order rationale as every other table in this schema.
  final String personId;

  /// Epoch milliseconds; when the row was first written.
  final int createdAt;

  /// Epoch milliseconds; updated on every mutation.
  final int updatedAt;

  /// Epoch milliseconds; `null` until archived. Keeping soft-delete
  /// symmetric with the other tables simplifies sync later.
  final int? deletedAt;

  /// Monotonically increasing per-row counter, incremented on every
  /// write. Same semantics as elsewhere.
  final int rowVersion;

  /// Which device last wrote this row. `null` in Phase 1.
  final String? lastWriterDeviceId;

  /// Which key generation decrypted this row's payload.
  final int keyVersion;

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`
  /// over an `EncryptedMedicationGroupPayload` JSON body.
  final Uint8List payload;
  const MedicationGroupRow({
    required this.id,
    required this.personId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.rowVersion,
    this.lastWriterDeviceId,
    required this.keyVersion,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['row_version'] = Variable<int>(rowVersion);
    if (!nullToAbsent || lastWriterDeviceId != null) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId);
    }
    map['key_version'] = Variable<int>(keyVersion);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  MedicationGroupsCompanion toCompanion(bool nullToAbsent) {
    return MedicationGroupsCompanion(
      id: Value(id),
      personId: Value(personId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rowVersion: Value(rowVersion),
      lastWriterDeviceId: lastWriterDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWriterDeviceId),
      keyVersion: Value(keyVersion),
      payload: Value(payload),
    );
  }

  factory MedicationGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationGroupRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      lastWriterDeviceId: serializer.fromJson<String?>(
        json['lastWriterDeviceId'],
      ),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'lastWriterDeviceId': serializer.toJson<String?>(lastWriterDeviceId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  MedicationGroupRow copyWith({
    String? id,
    String? personId,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? rowVersion,
    Value<String?> lastWriterDeviceId = const Value.absent(),
    int? keyVersion,
    Uint8List? payload,
  }) => MedicationGroupRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rowVersion: rowVersion ?? this.rowVersion,
    lastWriterDeviceId: lastWriterDeviceId.present
        ? lastWriterDeviceId.value
        : this.lastWriterDeviceId,
    keyVersion: keyVersion ?? this.keyVersion,
    payload: payload ?? this.payload,
  );
  MedicationGroupRow copyWithCompanion(MedicationGroupsCompanion data) {
    return MedicationGroupRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      lastWriterDeviceId: data.lastWriterDeviceId.present
          ? data.lastWriterDeviceId.value
          : this.lastWriterDeviceId,
      keyVersion: data.keyVersion.present
          ? data.keyVersion.value
          : this.keyVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationGroupRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationGroupRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.rowVersion == this.rowVersion &&
          other.lastWriterDeviceId == this.lastWriterDeviceId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class MedicationGroupsCompanion extends UpdateCompanion<MedicationGroupRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowVersion;
  final Value<String?> lastWriterDeviceId;
  final Value<int> keyVersion;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const MedicationGroupsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationGroupsCompanion.insert({
    required String id,
    required String personId,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<MedicationGroupRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowVersion,
    Expression<String>? lastWriterDeviceId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowVersion != null) 'row_version': rowVersion,
      if (lastWriterDeviceId != null)
        'last_writer_device_id': lastWriterDeviceId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowVersion,
    Value<String?>? lastWriterDeviceId,
    Value<int>? keyVersion,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return MedicationGroupsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowVersion: rowVersion ?? this.rowVersion,
      lastWriterDeviceId: lastWriterDeviceId ?? this.lastWriterDeviceId,
      keyVersion: keyVersion ?? this.keyVersion,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (lastWriterDeviceId.present) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationGroupsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareProvidersTable extends CareProviders
    with TableInfo<$CareProvidersTable, CareProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWriterDeviceIdMeta =
      const VerificationMeta('lastWriterDeviceId');
  @override
  late final GeneratedColumn<String> lastWriterDeviceId =
      GeneratedColumn<String>(
        'last_writer_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyVersionMeta = const VerificationMeta(
    'keyVersion',
  );
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
    'key_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareProviderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('last_writer_device_id')) {
      context.handle(
        _lastWriterDeviceIdMeta,
        lastWriterDeviceId.isAcceptableOrUnknown(
          data['last_writer_device_id']!,
          _lastWriterDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('key_version')) {
      context.handle(
        _keyVersionMeta,
        keyVersion.isAcceptableOrUnknown(data['key_version']!, _keyVersionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareProviderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      lastWriterDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_writer_device_id'],
      ),
      keyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CareProvidersTable createAlias(String alias) {
    return $CareProvidersTable(attachedDatabase, alias);
  }
}

class CareProviderRow extends DataClass implements Insertable<CareProviderRow> {
  /// Client-generated UUID v4.
  final String id;

  /// Owning Person's id. Not a declared SQL foreign key — Phase 2 sync
  /// needs to tolerate arrival order (a provider row may sync before
  /// its Person row).
  final String personId;

  /// Epoch milliseconds.
  final int createdAt;

  /// Epoch milliseconds.
  final int updatedAt;

  /// Epoch milliseconds; `null` means not archived.
  final int? deletedAt;

  /// Monotonically increasing per-row counter, incremented on every write.
  final int rowVersion;

  /// Identifier of the device that last wrote this row. `null` in Phase 1
  /// (single device); populated in Phase 2.
  final String? lastWriterDeviceId;

  /// Which key generation decrypted this row's payload.
  final int keyVersion;

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  final Uint8List payload;
  const CareProviderRow({
    required this.id,
    required this.personId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.rowVersion,
    this.lastWriterDeviceId,
    required this.keyVersion,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['row_version'] = Variable<int>(rowVersion);
    if (!nullToAbsent || lastWriterDeviceId != null) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId);
    }
    map['key_version'] = Variable<int>(keyVersion);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  CareProvidersCompanion toCompanion(bool nullToAbsent) {
    return CareProvidersCompanion(
      id: Value(id),
      personId: Value(personId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rowVersion: Value(rowVersion),
      lastWriterDeviceId: lastWriterDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWriterDeviceId),
      keyVersion: Value(keyVersion),
      payload: Value(payload),
    );
  }

  factory CareProviderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareProviderRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      lastWriterDeviceId: serializer.fromJson<String?>(
        json['lastWriterDeviceId'],
      ),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'lastWriterDeviceId': serializer.toJson<String?>(lastWriterDeviceId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  CareProviderRow copyWith({
    String? id,
    String? personId,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? rowVersion,
    Value<String?> lastWriterDeviceId = const Value.absent(),
    int? keyVersion,
    Uint8List? payload,
  }) => CareProviderRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rowVersion: rowVersion ?? this.rowVersion,
    lastWriterDeviceId: lastWriterDeviceId.present
        ? lastWriterDeviceId.value
        : this.lastWriterDeviceId,
    keyVersion: keyVersion ?? this.keyVersion,
    payload: payload ?? this.payload,
  );
  CareProviderRow copyWithCompanion(CareProvidersCompanion data) {
    return CareProviderRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      lastWriterDeviceId: data.lastWriterDeviceId.present
          ? data.lastWriterDeviceId.value
          : this.lastWriterDeviceId,
      keyVersion: data.keyVersion.present
          ? data.keyVersion.value
          : this.keyVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareProviderRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareProviderRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.rowVersion == this.rowVersion &&
          other.lastWriterDeviceId == this.lastWriterDeviceId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class CareProvidersCompanion extends UpdateCompanion<CareProviderRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowVersion;
  final Value<String?> lastWriterDeviceId;
  final Value<int> keyVersion;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const CareProvidersCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareProvidersCompanion.insert({
    required String id,
    required String personId,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<CareProviderRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowVersion,
    Expression<String>? lastWriterDeviceId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowVersion != null) 'row_version': rowVersion,
      if (lastWriterDeviceId != null)
        'last_writer_device_id': lastWriterDeviceId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareProvidersCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowVersion,
    Value<String?>? lastWriterDeviceId,
    Value<int>? keyVersion,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return CareProvidersCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowVersion: rowVersion ?? this.rowVersion,
      lastWriterDeviceId: lastWriterDeviceId ?? this.lastWriterDeviceId,
      keyVersion: keyVersion ?? this.keyVersion,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (lastWriterDeviceId.present) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareProvidersCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationEventsTable extends MedicationEvents
    with TableInfo<$MedicationEventsTable, MedicationEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWriterDeviceIdMeta =
      const VerificationMeta('lastWriterDeviceId');
  @override
  late final GeneratedColumn<String> lastWriterDeviceId =
      GeneratedColumn<String>(
        'last_writer_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyVersionMeta = const VerificationMeta(
    'keyVersion',
  );
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
    'key_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    personId,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('last_writer_device_id')) {
      context.handle(
        _lastWriterDeviceIdMeta,
        lastWriterDeviceId.isAcceptableOrUnknown(
          data['last_writer_device_id']!,
          _lastWriterDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('key_version')) {
      context.handle(
        _keyVersionMeta,
        keyVersion.isAcceptableOrUnknown(data['key_version']!, _keyVersionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      lastWriterDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_writer_device_id'],
      ),
      keyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $MedicationEventsTable createAlias(String alias) {
    return $MedicationEventsTable(attachedDatabase, alias);
  }
}

class MedicationEventRow extends DataClass
    implements Insertable<MedicationEventRow> {
  /// Client-generated UUID v4.
  final String id;

  /// The medication this event belongs to. Not a declared SQL foreign
  /// key — Phase 2 sync needs to tolerate arrival order (an event may
  /// sync before its parent medication row).
  final String medicationId;

  /// Owning Person's id — duplicated from the parent medication so
  /// listing events for a Person works without a join, and so AAD
  /// binding can scope every ciphertext to its Person like the other
  /// tables.
  final String personId;

  /// Epoch milliseconds — when the change *took effect* in the
  /// patient's timeline. Equals [createdAt] for auto-logged events
  /// (the change happened at the moment the user saved it), but
  /// manually-entered backfill events set this to the historical
  /// date ("this dose started on 2024-03-01, recorded today").
  final int occurredAt;

  /// Epoch milliseconds — when this row was first written.
  final int createdAt;

  /// Epoch milliseconds — bumped on any payload mutation (future
  /// manual correction flow). For auto-logged events this equals
  /// [createdAt] for the lifetime of the row.
  final int updatedAt;

  /// Epoch milliseconds; `null` means not archived. Archiving an
  /// event preserves history for Phase 2 sync tombstones and lets
  /// users "undo" a mis-logged event without actually losing it.
  final int? deletedAt;

  /// Monotonically increasing per-row counter, incremented on every
  /// write.
  final int rowVersion;

  /// Identifier of the device that last wrote this row. `null` in
  /// Phase 1 (single device); populated in Phase 2.
  final String? lastWriterDeviceId;

  /// Which key generation decrypted this row's payload.
  final int keyVersion;

  /// Envelope-encrypted bytes produced by `EncryptedPayload.toBytes()`.
  final Uint8List payload;
  const MedicationEventRow({
    required this.id,
    required this.medicationId,
    required this.personId,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.rowVersion,
    this.lastWriterDeviceId,
    required this.keyVersion,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['person_id'] = Variable<String>(personId);
    map['occurred_at'] = Variable<int>(occurredAt);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['row_version'] = Variable<int>(rowVersion);
    if (!nullToAbsent || lastWriterDeviceId != null) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId);
    }
    map['key_version'] = Variable<int>(keyVersion);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  MedicationEventsCompanion toCompanion(bool nullToAbsent) {
    return MedicationEventsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      personId: Value(personId),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rowVersion: Value(rowVersion),
      lastWriterDeviceId: lastWriterDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWriterDeviceId),
      keyVersion: Value(keyVersion),
      payload: Value(payload),
    );
  }

  factory MedicationEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationEventRow(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      personId: serializer.fromJson<String>(json['personId']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      lastWriterDeviceId: serializer.fromJson<String?>(
        json['lastWriterDeviceId'],
      ),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'personId': serializer.toJson<String>(personId),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'lastWriterDeviceId': serializer.toJson<String?>(lastWriterDeviceId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  MedicationEventRow copyWith({
    String? id,
    String? medicationId,
    String? personId,
    int? occurredAt,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? rowVersion,
    Value<String?> lastWriterDeviceId = const Value.absent(),
    int? keyVersion,
    Uint8List? payload,
  }) => MedicationEventRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    personId: personId ?? this.personId,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rowVersion: rowVersion ?? this.rowVersion,
    lastWriterDeviceId: lastWriterDeviceId.present
        ? lastWriterDeviceId.value
        : this.lastWriterDeviceId,
    keyVersion: keyVersion ?? this.keyVersion,
    payload: payload ?? this.payload,
  );
  MedicationEventRow copyWithCompanion(MedicationEventsCompanion data) {
    return MedicationEventRow(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      personId: data.personId.present ? data.personId.value : this.personId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      lastWriterDeviceId: data.lastWriterDeviceId.present
          ? data.lastWriterDeviceId.value
          : this.lastWriterDeviceId,
      keyVersion: data.keyVersion.present
          ? data.keyVersion.value
          : this.keyVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEventRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('personId: $personId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    personId,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    rowVersion,
    lastWriterDeviceId,
    keyVersion,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationEventRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.personId == this.personId &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.rowVersion == this.rowVersion &&
          other.lastWriterDeviceId == this.lastWriterDeviceId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class MedicationEventsCompanion extends UpdateCompanion<MedicationEventRow> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<String> personId;
  final Value<int> occurredAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowVersion;
  final Value<String?> lastWriterDeviceId;
  final Value<int> keyVersion;
  final Value<Uint8List> payload;
  final Value<int> rowid;
  const MedicationEventsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.personId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationEventsCompanion.insert({
    required String id,
    required String medicationId,
    required String personId,
    required int occurredAt,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.lastWriterDeviceId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    required Uint8List payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       personId = Value(personId),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<MedicationEventRow> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<String>? personId,
    Expression<int>? occurredAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowVersion,
    Expression<String>? lastWriterDeviceId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (personId != null) 'person_id': personId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowVersion != null) 'row_version': rowVersion,
      if (lastWriterDeviceId != null)
        'last_writer_device_id': lastWriterDeviceId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<String>? personId,
    Value<int>? occurredAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowVersion,
    Value<String?>? lastWriterDeviceId,
    Value<int>? keyVersion,
    Value<Uint8List>? payload,
    Value<int>? rowid,
  }) {
    return MedicationEventsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      personId: personId ?? this.personId,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowVersion: rowVersion ?? this.rowVersion,
      lastWriterDeviceId: lastWriterDeviceId ?? this.lastWriterDeviceId,
      keyVersion: keyVersion ?? this.keyVersion,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (lastWriterDeviceId.present) {
      map['last_writer_device_id'] = Variable<String>(lastWriterDeviceId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEventsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('personId: $personId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('lastWriterDeviceId: $lastWriterDeviceId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $DoseLogsTable doseLogs = $DoseLogsTable(this);
  late final $MedicationGroupsTable medicationGroups = $MedicationGroupsTable(
    this,
  );
  late final $CareProvidersTable careProviders = $CareProvidersTable(this);
  late final $MedicationEventsTable medicationEvents = $MedicationEventsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    persons,
    medications,
    doseLogs,
    medicationGroups,
    careProviders,
    medicationEvents,
  ];
}

typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      required Uint8List payload,
      Value<int> rowid,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      Value<Uint8List> payload,
      Value<int> rowid,
    });

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          PersonRow,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (PersonRow, BaseReferences<_$AppDatabase, $PersonsTable, PersonRow>),
          PersonRow,
          PrefetchHooks Function()
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                required Uint8List payload,
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      PersonRow,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (PersonRow, BaseReferences<_$AppDatabase, $PersonsTable, PersonRow>),
      PersonRow,
      PrefetchHooks Function()
    >;
typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String personId,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      required Uint8List payload,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      Value<Uint8List> payload,
      Value<int> rowid,
    });

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          MedicationRow,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (
            MedicationRow,
            BaseReferences<_$AppDatabase, $MedicationsTable, MedicationRow>,
          ),
          MedicationRow,
          PrefetchHooks Function()
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                personId: personId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                required Uint8List payload,
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                personId: personId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      MedicationRow,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (
        MedicationRow,
        BaseReferences<_$AppDatabase, $MedicationsTable, MedicationRow>,
      ),
      MedicationRow,
      PrefetchHooks Function()
    >;
typedef $$DoseLogsTableCreateCompanionBuilder =
    DoseLogsCompanion Function({
      required String id,
      required String personId,
      required String medicationId,
      required int scheduledAtUtcMs,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      required Uint8List payload,
      Value<int> rowid,
    });
typedef $$DoseLogsTableUpdateCompanionBuilder =
    DoseLogsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> medicationId,
      Value<int> scheduledAtUtcMs,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      Value<Uint8List> payload,
      Value<int> rowid,
    });

class $$DoseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DoseLogsTable> {
  $$DoseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledAtUtcMs => $composableBuilder(
    column: $table.scheduledAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DoseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseLogsTable> {
  $$DoseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAtUtcMs => $composableBuilder(
    column: $table.scheduledAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DoseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseLogsTable> {
  $$DoseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduledAtUtcMs => $composableBuilder(
    column: $table.scheduledAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$DoseLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoseLogsTable,
          DoseLogRow,
          $$DoseLogsTableFilterComposer,
          $$DoseLogsTableOrderingComposer,
          $$DoseLogsTableAnnotationComposer,
          $$DoseLogsTableCreateCompanionBuilder,
          $$DoseLogsTableUpdateCompanionBuilder,
          (
            DoseLogRow,
            BaseReferences<_$AppDatabase, $DoseLogsTable, DoseLogRow>,
          ),
          DoseLogRow,
          PrefetchHooks Function()
        > {
  $$DoseLogsTableTableManager(_$AppDatabase db, $DoseLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int> scheduledAtUtcMs = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoseLogsCompanion(
                id: id,
                personId: personId,
                medicationId: medicationId,
                scheduledAtUtcMs: scheduledAtUtcMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String medicationId,
                required int scheduledAtUtcMs,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                required Uint8List payload,
                Value<int> rowid = const Value.absent(),
              }) => DoseLogsCompanion.insert(
                id: id,
                personId: personId,
                medicationId: medicationId,
                scheduledAtUtcMs: scheduledAtUtcMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DoseLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoseLogsTable,
      DoseLogRow,
      $$DoseLogsTableFilterComposer,
      $$DoseLogsTableOrderingComposer,
      $$DoseLogsTableAnnotationComposer,
      $$DoseLogsTableCreateCompanionBuilder,
      $$DoseLogsTableUpdateCompanionBuilder,
      (DoseLogRow, BaseReferences<_$AppDatabase, $DoseLogsTable, DoseLogRow>),
      DoseLogRow,
      PrefetchHooks Function()
    >;
typedef $$MedicationGroupsTableCreateCompanionBuilder =
    MedicationGroupsCompanion Function({
      required String id,
      required String personId,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      required Uint8List payload,
      Value<int> rowid,
    });
typedef $$MedicationGroupsTableUpdateCompanionBuilder =
    MedicationGroupsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      Value<Uint8List> payload,
      Value<int> rowid,
    });

class $$MedicationGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationGroupsTable> {
  $$MedicationGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationGroupsTable> {
  $$MedicationGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationGroupsTable> {
  $$MedicationGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$MedicationGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationGroupsTable,
          MedicationGroupRow,
          $$MedicationGroupsTableFilterComposer,
          $$MedicationGroupsTableOrderingComposer,
          $$MedicationGroupsTableAnnotationComposer,
          $$MedicationGroupsTableCreateCompanionBuilder,
          $$MedicationGroupsTableUpdateCompanionBuilder,
          (
            MedicationGroupRow,
            BaseReferences<
              _$AppDatabase,
              $MedicationGroupsTable,
              MedicationGroupRow
            >,
          ),
          MedicationGroupRow,
          PrefetchHooks Function()
        > {
  $$MedicationGroupsTableTableManager(
    _$AppDatabase db,
    $MedicationGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationGroupsCompanion(
                id: id,
                personId: personId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                required Uint8List payload,
                Value<int> rowid = const Value.absent(),
              }) => MedicationGroupsCompanion.insert(
                id: id,
                personId: personId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationGroupsTable,
      MedicationGroupRow,
      $$MedicationGroupsTableFilterComposer,
      $$MedicationGroupsTableOrderingComposer,
      $$MedicationGroupsTableAnnotationComposer,
      $$MedicationGroupsTableCreateCompanionBuilder,
      $$MedicationGroupsTableUpdateCompanionBuilder,
      (
        MedicationGroupRow,
        BaseReferences<
          _$AppDatabase,
          $MedicationGroupsTable,
          MedicationGroupRow
        >,
      ),
      MedicationGroupRow,
      PrefetchHooks Function()
    >;
typedef $$CareProvidersTableCreateCompanionBuilder =
    CareProvidersCompanion Function({
      required String id,
      required String personId,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      required Uint8List payload,
      Value<int> rowid,
    });
typedef $$CareProvidersTableUpdateCompanionBuilder =
    CareProvidersCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      Value<Uint8List> payload,
      Value<int> rowid,
    });

class $$CareProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $CareProvidersTable> {
  $$CareProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $CareProvidersTable> {
  $$CareProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareProvidersTable> {
  $$CareProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$CareProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareProvidersTable,
          CareProviderRow,
          $$CareProvidersTableFilterComposer,
          $$CareProvidersTableOrderingComposer,
          $$CareProvidersTableAnnotationComposer,
          $$CareProvidersTableCreateCompanionBuilder,
          $$CareProvidersTableUpdateCompanionBuilder,
          (
            CareProviderRow,
            BaseReferences<_$AppDatabase, $CareProvidersTable, CareProviderRow>,
          ),
          CareProviderRow,
          PrefetchHooks Function()
        > {
  $$CareProvidersTableTableManager(_$AppDatabase db, $CareProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareProvidersCompanion(
                id: id,
                personId: personId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                required Uint8List payload,
                Value<int> rowid = const Value.absent(),
              }) => CareProvidersCompanion.insert(
                id: id,
                personId: personId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareProvidersTable,
      CareProviderRow,
      $$CareProvidersTableFilterComposer,
      $$CareProvidersTableOrderingComposer,
      $$CareProvidersTableAnnotationComposer,
      $$CareProvidersTableCreateCompanionBuilder,
      $$CareProvidersTableUpdateCompanionBuilder,
      (
        CareProviderRow,
        BaseReferences<_$AppDatabase, $CareProvidersTable, CareProviderRow>,
      ),
      CareProviderRow,
      PrefetchHooks Function()
    >;
typedef $$MedicationEventsTableCreateCompanionBuilder =
    MedicationEventsCompanion Function({
      required String id,
      required String medicationId,
      required String personId,
      required int occurredAt,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      required Uint8List payload,
      Value<int> rowid,
    });
typedef $$MedicationEventsTableUpdateCompanionBuilder =
    MedicationEventsCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<String> personId,
      Value<int> occurredAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowVersion,
      Value<String?> lastWriterDeviceId,
      Value<int> keyVersion,
      Value<Uint8List> payload,
      Value<int> rowid,
    });

class $$MedicationEventsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationEventsTable> {
  $$MedicationEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationEventsTable> {
  $$MedicationEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationEventsTable> {
  $$MedicationEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastWriterDeviceId => $composableBuilder(
    column: $table.lastWriterDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keyVersion => $composableBuilder(
    column: $table.keyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$MedicationEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationEventsTable,
          MedicationEventRow,
          $$MedicationEventsTableFilterComposer,
          $$MedicationEventsTableOrderingComposer,
          $$MedicationEventsTableAnnotationComposer,
          $$MedicationEventsTableCreateCompanionBuilder,
          $$MedicationEventsTableUpdateCompanionBuilder,
          (
            MedicationEventRow,
            BaseReferences<
              _$AppDatabase,
              $MedicationEventsTable,
              MedicationEventRow
            >,
          ),
          MedicationEventRow,
          PrefetchHooks Function()
        > {
  $$MedicationEventsTableTableManager(
    _$AppDatabase db,
    $MedicationEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationEventsCompanion(
                id: id,
                medicationId: medicationId,
                personId: personId,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required String personId,
                required int occurredAt,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<String?> lastWriterDeviceId = const Value.absent(),
                Value<int> keyVersion = const Value.absent(),
                required Uint8List payload,
                Value<int> rowid = const Value.absent(),
              }) => MedicationEventsCompanion.insert(
                id: id,
                medicationId: medicationId,
                personId: personId,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowVersion: rowVersion,
                lastWriterDeviceId: lastWriterDeviceId,
                keyVersion: keyVersion,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationEventsTable,
      MedicationEventRow,
      $$MedicationEventsTableFilterComposer,
      $$MedicationEventsTableOrderingComposer,
      $$MedicationEventsTableAnnotationComposer,
      $$MedicationEventsTableCreateCompanionBuilder,
      $$MedicationEventsTableUpdateCompanionBuilder,
      (
        MedicationEventRow,
        BaseReferences<
          _$AppDatabase,
          $MedicationEventsTable,
          MedicationEventRow
        >,
      ),
      MedicationEventRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$DoseLogsTableTableManager get doseLogs =>
      $$DoseLogsTableTableManager(_db, _db.doseLogs);
  $$MedicationGroupsTableTableManager get medicationGroups =>
      $$MedicationGroupsTableTableManager(_db, _db.medicationGroups);
  $$CareProvidersTableTableManager get careProviders =>
      $$CareProvidersTableTableManager(_db, _db.careProviders);
  $$MedicationEventsTableTableManager get medicationEvents =>
      $$MedicationEventsTableTableManager(_db, _db.medicationEvents);
}
