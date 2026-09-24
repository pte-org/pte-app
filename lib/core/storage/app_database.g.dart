// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AnswerOutboxTableTable extends AnswerOutboxTable
    with TableInfo<$AnswerOutboxTableTable, AnswerOutbox> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerOutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptPublicIdMeta = const VerificationMeta(
    'attemptPublicId',
  );
  @override
  late final GeneratedColumn<String> attemptPublicId = GeneratedColumn<String>(
    'attempt_public_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedItemPublicIdMeta =
      const VerificationMeta('pinnedItemPublicId');
  @override
  late final GeneratedColumn<String> pinnedItemPublicId =
      GeneratedColumn<String>(
        'pinned_item_public_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    attemptPublicId,
    pinnedItemPublicId,
    payload,
    status,
    lastSyncError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerOutbox> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_public_id')) {
      context.handle(
        _attemptPublicIdMeta,
        attemptPublicId.isAcceptableOrUnknown(
          data['attempt_public_id']!,
          _attemptPublicIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptPublicIdMeta);
    }
    if (data.containsKey('pinned_item_public_id')) {
      context.handle(
        _pinnedItemPublicIdMeta,
        pinnedItemPublicId.isAcceptableOrUnknown(
          data['pinned_item_public_id']!,
          _pinnedItemPublicIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pinnedItemPublicIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptPublicId, pinnedItemPublicId};
  @override
  AnswerOutbox map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerOutbox(
      attemptPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_public_id'],
      )!,
      pinnedItemPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinned_item_public_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AnswerOutboxTableTable createAlias(String alias) {
    return $AnswerOutboxTableTable(attachedDatabase, alias);
  }
}

class AnswerOutbox extends DataClass implements Insertable<AnswerOutbox> {
  final String attemptPublicId;
  final String pinnedItemPublicId;
  final String payload;
  final String status;
  final String? lastSyncError;
  final int createdAt;
  final int updatedAt;
  const AnswerOutbox({
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required this.payload,
    required this.status,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_public_id'] = Variable<String>(attemptPublicId);
    map['pinned_item_public_id'] = Variable<String>(pinnedItemPublicId);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AnswerOutboxTableCompanion toCompanion(bool nullToAbsent) {
    return AnswerOutboxTableCompanion(
      attemptPublicId: Value(attemptPublicId),
      pinnedItemPublicId: Value(pinnedItemPublicId),
      payload: Value(payload),
      status: Value(status),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnswerOutbox.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerOutbox(
      attemptPublicId: serializer.fromJson<String>(json['attemptPublicId']),
      pinnedItemPublicId: serializer.fromJson<String>(
        json['pinnedItemPublicId'],
      ),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptPublicId': serializer.toJson<String>(attemptPublicId),
      'pinnedItemPublicId': serializer.toJson<String>(pinnedItemPublicId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AnswerOutbox copyWith({
    String? attemptPublicId,
    String? pinnedItemPublicId,
    String? payload,
    String? status,
    Value<String?> lastSyncError = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => AnswerOutbox(
    attemptPublicId: attemptPublicId ?? this.attemptPublicId,
    pinnedItemPublicId: pinnedItemPublicId ?? this.pinnedItemPublicId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnswerOutbox copyWithCompanion(AnswerOutboxTableCompanion data) {
    return AnswerOutbox(
      attemptPublicId: data.attemptPublicId.present
          ? data.attemptPublicId.value
          : this.attemptPublicId,
      pinnedItemPublicId: data.pinnedItemPublicId.present
          ? data.pinnedItemPublicId.value
          : this.pinnedItemPublicId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerOutbox(')
          ..write('attemptPublicId: $attemptPublicId, ')
          ..write('pinnedItemPublicId: $pinnedItemPublicId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attemptPublicId,
    pinnedItemPublicId,
    payload,
    status,
    lastSyncError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerOutbox &&
          other.attemptPublicId == this.attemptPublicId &&
          other.pinnedItemPublicId == this.pinnedItemPublicId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.lastSyncError == this.lastSyncError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnswerOutboxTableCompanion extends UpdateCompanion<AnswerOutbox> {
  final Value<String> attemptPublicId;
  final Value<String> pinnedItemPublicId;
  final Value<String> payload;
  final Value<String> status;
  final Value<String?> lastSyncError;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AnswerOutboxTableCompanion({
    this.attemptPublicId = const Value.absent(),
    this.pinnedItemPublicId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerOutboxTableCompanion.insert({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String payload,
    required String status,
    this.lastSyncError = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : attemptPublicId = Value(attemptPublicId),
       pinnedItemPublicId = Value(pinnedItemPublicId),
       payload = Value(payload),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnswerOutbox> custom({
    Expression<String>? attemptPublicId,
    Expression<String>? pinnedItemPublicId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<String>? lastSyncError,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptPublicId != null) 'attempt_public_id': attemptPublicId,
      if (pinnedItemPublicId != null)
        'pinned_item_public_id': pinnedItemPublicId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerOutboxTableCompanion copyWith({
    Value<String>? attemptPublicId,
    Value<String>? pinnedItemPublicId,
    Value<String>? payload,
    Value<String>? status,
    Value<String?>? lastSyncError,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnswerOutboxTableCompanion(
      attemptPublicId: attemptPublicId ?? this.attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId ?? this.pinnedItemPublicId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptPublicId.present) {
      map['attempt_public_id'] = Variable<String>(attemptPublicId.value);
    }
    if (pinnedItemPublicId.present) {
      map['pinned_item_public_id'] = Variable<String>(pinnedItemPublicId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerOutboxTableCompanion(')
          ..write('attemptPublicId: $attemptPublicId, ')
          ..write('pinnedItemPublicId: $pinnedItemPublicId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMediaUploadTableTable extends PendingMediaUploadTable
    with TableInfo<$PendingMediaUploadTableTable, PendingMediaUpload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMediaUploadTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptPublicIdMeta = const VerificationMeta(
    'attemptPublicId',
  );
  @override
  late final GeneratedColumn<String> attemptPublicId = GeneratedColumn<String>(
    'attempt_public_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedItemPublicIdMeta =
      const VerificationMeta('pinnedItemPublicId');
  @override
  late final GeneratedColumn<String> pinnedItemPublicId =
      GeneratedColumn<String>(
        'pinned_item_public_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaPublicIdMeta = const VerificationMeta(
    'mediaPublicId',
  );
  @override
  late final GeneratedColumn<String> mediaPublicId = GeneratedColumn<String>(
    'media_public_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadUrlMeta = const VerificationMeta(
    'uploadUrl',
  );
  @override
  late final GeneratedColumn<String> uploadUrl = GeneratedColumn<String>(
    'upload_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadUrlExpiresAtMeta =
      const VerificationMeta('uploadUrlExpiresAt');
  @override
  late final GeneratedColumn<int> uploadUrlExpiresAt = GeneratedColumn<int>(
    'upload_url_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudinaryApiKeyMeta = const VerificationMeta(
    'cloudinaryApiKey',
  );
  @override
  late final GeneratedColumn<String> cloudinaryApiKey = GeneratedColumn<String>(
    'cloudinary_api_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudinaryTimestampMeta =
      const VerificationMeta('cloudinaryTimestamp');
  @override
  late final GeneratedColumn<String> cloudinaryTimestamp =
      GeneratedColumn<String>(
        'cloudinary_timestamp',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinaryUploadSignatureMeta =
      const VerificationMeta('cloudinaryUploadSignature');
  @override
  late final GeneratedColumn<String> cloudinaryUploadSignature =
      GeneratedColumn<String>(
        'cloudinary_upload_signature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinaryFolderMeta = const VerificationMeta(
    'cloudinaryFolder',
  );
  @override
  late final GeneratedColumn<String> cloudinaryFolder = GeneratedColumn<String>(
    'cloudinary_folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudinaryResourceTypeMeta =
      const VerificationMeta('cloudinaryResourceType');
  @override
  late final GeneratedColumn<String> cloudinaryResourceType =
      GeneratedColumn<String>(
        'cloudinary_resource_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinaryPublicIdMeta =
      const VerificationMeta('cloudinaryPublicId');
  @override
  late final GeneratedColumn<String> cloudinaryPublicId =
      GeneratedColumn<String>(
        'cloudinary_public_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinaryAssetIdMeta = const VerificationMeta(
    'cloudinaryAssetId',
  );
  @override
  late final GeneratedColumn<String> cloudinaryAssetId =
      GeneratedColumn<String>(
        'cloudinary_asset_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinarySecureUrlMeta =
      const VerificationMeta('cloudinarySecureUrl');
  @override
  late final GeneratedColumn<String> cloudinarySecureUrl =
      GeneratedColumn<String>(
        'cloudinary_secure_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinaryFormatMeta = const VerificationMeta(
    'cloudinaryFormat',
  );
  @override
  late final GeneratedColumn<String> cloudinaryFormat = GeneratedColumn<String>(
    'cloudinary_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudinaryBytesMeta = const VerificationMeta(
    'cloudinaryBytes',
  );
  @override
  late final GeneratedColumn<int> cloudinaryBytes = GeneratedColumn<int>(
    'cloudinary_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudinaryDurationSecondsMeta =
      const VerificationMeta('cloudinaryDurationSeconds');
  @override
  late final GeneratedColumn<int> cloudinaryDurationSeconds =
      GeneratedColumn<int>(
        'cloudinary_duration_seconds',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudinaryVersionMeta = const VerificationMeta(
    'cloudinaryVersion',
  );
  @override
  late final GeneratedColumn<int> cloudinaryVersion = GeneratedColumn<int>(
    'cloudinary_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudinarySignatureMeta =
      const VerificationMeta('cloudinarySignature');
  @override
  late final GeneratedColumn<String> cloudinarySignature =
      GeneratedColumn<String>(
        'cloudinary_signature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    attemptPublicId,
    pinnedItemPublicId,
    localFilePath,
    mediaPublicId,
    uploadUrl,
    uploadUrlExpiresAt,
    cloudinaryApiKey,
    cloudinaryTimestamp,
    cloudinaryUploadSignature,
    cloudinaryFolder,
    cloudinaryResourceType,
    cloudinaryPublicId,
    cloudinaryAssetId,
    cloudinarySecureUrl,
    cloudinaryFormat,
    cloudinaryBytes,
    cloudinaryDurationSeconds,
    cloudinaryVersion,
    cloudinarySignature,
    status,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_media_upload_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMediaUpload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_public_id')) {
      context.handle(
        _attemptPublicIdMeta,
        attemptPublicId.isAcceptableOrUnknown(
          data['attempt_public_id']!,
          _attemptPublicIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptPublicIdMeta);
    }
    if (data.containsKey('pinned_item_public_id')) {
      context.handle(
        _pinnedItemPublicIdMeta,
        pinnedItemPublicId.isAcceptableOrUnknown(
          data['pinned_item_public_id']!,
          _pinnedItemPublicIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pinnedItemPublicIdMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('media_public_id')) {
      context.handle(
        _mediaPublicIdMeta,
        mediaPublicId.isAcceptableOrUnknown(
          data['media_public_id']!,
          _mediaPublicIdMeta,
        ),
      );
    }
    if (data.containsKey('upload_url')) {
      context.handle(
        _uploadUrlMeta,
        uploadUrl.isAcceptableOrUnknown(data['upload_url']!, _uploadUrlMeta),
      );
    }
    if (data.containsKey('upload_url_expires_at')) {
      context.handle(
        _uploadUrlExpiresAtMeta,
        uploadUrlExpiresAt.isAcceptableOrUnknown(
          data['upload_url_expires_at']!,
          _uploadUrlExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_api_key')) {
      context.handle(
        _cloudinaryApiKeyMeta,
        cloudinaryApiKey.isAcceptableOrUnknown(
          data['cloudinary_api_key']!,
          _cloudinaryApiKeyMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_timestamp')) {
      context.handle(
        _cloudinaryTimestampMeta,
        cloudinaryTimestamp.isAcceptableOrUnknown(
          data['cloudinary_timestamp']!,
          _cloudinaryTimestampMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_upload_signature')) {
      context.handle(
        _cloudinaryUploadSignatureMeta,
        cloudinaryUploadSignature.isAcceptableOrUnknown(
          data['cloudinary_upload_signature']!,
          _cloudinaryUploadSignatureMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_folder')) {
      context.handle(
        _cloudinaryFolderMeta,
        cloudinaryFolder.isAcceptableOrUnknown(
          data['cloudinary_folder']!,
          _cloudinaryFolderMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_resource_type')) {
      context.handle(
        _cloudinaryResourceTypeMeta,
        cloudinaryResourceType.isAcceptableOrUnknown(
          data['cloudinary_resource_type']!,
          _cloudinaryResourceTypeMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_public_id')) {
      context.handle(
        _cloudinaryPublicIdMeta,
        cloudinaryPublicId.isAcceptableOrUnknown(
          data['cloudinary_public_id']!,
          _cloudinaryPublicIdMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_asset_id')) {
      context.handle(
        _cloudinaryAssetIdMeta,
        cloudinaryAssetId.isAcceptableOrUnknown(
          data['cloudinary_asset_id']!,
          _cloudinaryAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_secure_url')) {
      context.handle(
        _cloudinarySecureUrlMeta,
        cloudinarySecureUrl.isAcceptableOrUnknown(
          data['cloudinary_secure_url']!,
          _cloudinarySecureUrlMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_format')) {
      context.handle(
        _cloudinaryFormatMeta,
        cloudinaryFormat.isAcceptableOrUnknown(
          data['cloudinary_format']!,
          _cloudinaryFormatMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_bytes')) {
      context.handle(
        _cloudinaryBytesMeta,
        cloudinaryBytes.isAcceptableOrUnknown(
          data['cloudinary_bytes']!,
          _cloudinaryBytesMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_duration_seconds')) {
      context.handle(
        _cloudinaryDurationSecondsMeta,
        cloudinaryDurationSeconds.isAcceptableOrUnknown(
          data['cloudinary_duration_seconds']!,
          _cloudinaryDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_version')) {
      context.handle(
        _cloudinaryVersionMeta,
        cloudinaryVersion.isAcceptableOrUnknown(
          data['cloudinary_version']!,
          _cloudinaryVersionMeta,
        ),
      );
    }
    if (data.containsKey('cloudinary_signature')) {
      context.handle(
        _cloudinarySignatureMeta,
        cloudinarySignature.isAcceptableOrUnknown(
          data['cloudinary_signature']!,
          _cloudinarySignatureMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptPublicId, pinnedItemPublicId};
  @override
  PendingMediaUpload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMediaUpload(
      attemptPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_public_id'],
      )!,
      pinnedItemPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinned_item_public_id'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      mediaPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_public_id'],
      ),
      uploadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_url'],
      ),
      uploadUrlExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upload_url_expires_at'],
      ),
      cloudinaryApiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_api_key'],
      ),
      cloudinaryTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_timestamp'],
      ),
      cloudinaryUploadSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_upload_signature'],
      ),
      cloudinaryFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_folder'],
      ),
      cloudinaryResourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_resource_type'],
      ),
      cloudinaryPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_public_id'],
      ),
      cloudinaryAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_asset_id'],
      ),
      cloudinarySecureUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_secure_url'],
      ),
      cloudinaryFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_format'],
      ),
      cloudinaryBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloudinary_bytes'],
      ),
      cloudinaryDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloudinary_duration_seconds'],
      ),
      cloudinaryVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloudinary_version'],
      ),
      cloudinarySignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudinary_signature'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingMediaUploadTableTable createAlias(String alias) {
    return $PendingMediaUploadTableTable(attachedDatabase, alias);
  }
}

class PendingMediaUpload extends DataClass
    implements Insertable<PendingMediaUpload> {
  final String attemptPublicId;
  final String pinnedItemPublicId;

  /// Local temp-file path the recording was written to — never held only
  /// in memory, so a deferred/retried upload survives process death.
  final String localFilePath;

  /// Nullable until the first successful presign.
  final String? mediaPublicId;

  /// Nullable, re-set on every (re-)presign.
  final String? uploadUrl;

  /// Epoch ms, nullable, re-set on every (re-)presign.
  final int? uploadUrlExpiresAt;

  /// Signed Cloudinary upload fields. These survive a process restart between
  /// presign and the direct upload.
  final String? cloudinaryApiKey;
  final String? cloudinaryTimestamp;
  final String? cloudinaryUploadSignature;
  final String? cloudinaryFolder;
  final String? cloudinaryResourceType;
  final String? cloudinaryPublicId;

  /// Provider response persisted before the API completion call. This makes
  /// the completing phase restart-safe without re-uploading the recording.
  final String? cloudinaryAssetId;
  final String? cloudinarySecureUrl;
  final String? cloudinaryFormat;
  final int? cloudinaryBytes;
  final int? cloudinaryDurationSeconds;
  final int? cloudinaryVersion;
  final String? cloudinarySignature;
  final String status;
  final String? lastError;
  const PendingMediaUpload({
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required this.localFilePath,
    this.mediaPublicId,
    this.uploadUrl,
    this.uploadUrlExpiresAt,
    this.cloudinaryApiKey,
    this.cloudinaryTimestamp,
    this.cloudinaryUploadSignature,
    this.cloudinaryFolder,
    this.cloudinaryResourceType,
    this.cloudinaryPublicId,
    this.cloudinaryAssetId,
    this.cloudinarySecureUrl,
    this.cloudinaryFormat,
    this.cloudinaryBytes,
    this.cloudinaryDurationSeconds,
    this.cloudinaryVersion,
    this.cloudinarySignature,
    required this.status,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_public_id'] = Variable<String>(attemptPublicId);
    map['pinned_item_public_id'] = Variable<String>(pinnedItemPublicId);
    map['local_file_path'] = Variable<String>(localFilePath);
    if (!nullToAbsent || mediaPublicId != null) {
      map['media_public_id'] = Variable<String>(mediaPublicId);
    }
    if (!nullToAbsent || uploadUrl != null) {
      map['upload_url'] = Variable<String>(uploadUrl);
    }
    if (!nullToAbsent || uploadUrlExpiresAt != null) {
      map['upload_url_expires_at'] = Variable<int>(uploadUrlExpiresAt);
    }
    if (!nullToAbsent || cloudinaryApiKey != null) {
      map['cloudinary_api_key'] = Variable<String>(cloudinaryApiKey);
    }
    if (!nullToAbsent || cloudinaryTimestamp != null) {
      map['cloudinary_timestamp'] = Variable<String>(cloudinaryTimestamp);
    }
    if (!nullToAbsent || cloudinaryUploadSignature != null) {
      map['cloudinary_upload_signature'] = Variable<String>(
        cloudinaryUploadSignature,
      );
    }
    if (!nullToAbsent || cloudinaryFolder != null) {
      map['cloudinary_folder'] = Variable<String>(cloudinaryFolder);
    }
    if (!nullToAbsent || cloudinaryResourceType != null) {
      map['cloudinary_resource_type'] = Variable<String>(
        cloudinaryResourceType,
      );
    }
    if (!nullToAbsent || cloudinaryPublicId != null) {
      map['cloudinary_public_id'] = Variable<String>(cloudinaryPublicId);
    }
    if (!nullToAbsent || cloudinaryAssetId != null) {
      map['cloudinary_asset_id'] = Variable<String>(cloudinaryAssetId);
    }
    if (!nullToAbsent || cloudinarySecureUrl != null) {
      map['cloudinary_secure_url'] = Variable<String>(cloudinarySecureUrl);
    }
    if (!nullToAbsent || cloudinaryFormat != null) {
      map['cloudinary_format'] = Variable<String>(cloudinaryFormat);
    }
    if (!nullToAbsent || cloudinaryBytes != null) {
      map['cloudinary_bytes'] = Variable<int>(cloudinaryBytes);
    }
    if (!nullToAbsent || cloudinaryDurationSeconds != null) {
      map['cloudinary_duration_seconds'] = Variable<int>(
        cloudinaryDurationSeconds,
      );
    }
    if (!nullToAbsent || cloudinaryVersion != null) {
      map['cloudinary_version'] = Variable<int>(cloudinaryVersion);
    }
    if (!nullToAbsent || cloudinarySignature != null) {
      map['cloudinary_signature'] = Variable<String>(cloudinarySignature);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingMediaUploadTableCompanion toCompanion(bool nullToAbsent) {
    return PendingMediaUploadTableCompanion(
      attemptPublicId: Value(attemptPublicId),
      pinnedItemPublicId: Value(pinnedItemPublicId),
      localFilePath: Value(localFilePath),
      mediaPublicId: mediaPublicId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPublicId),
      uploadUrl: uploadUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadUrl),
      uploadUrlExpiresAt: uploadUrlExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadUrlExpiresAt),
      cloudinaryApiKey: cloudinaryApiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryApiKey),
      cloudinaryTimestamp: cloudinaryTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryTimestamp),
      cloudinaryUploadSignature:
          cloudinaryUploadSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryUploadSignature),
      cloudinaryFolder: cloudinaryFolder == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryFolder),
      cloudinaryResourceType: cloudinaryResourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryResourceType),
      cloudinaryPublicId: cloudinaryPublicId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryPublicId),
      cloudinaryAssetId: cloudinaryAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryAssetId),
      cloudinarySecureUrl: cloudinarySecureUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinarySecureUrl),
      cloudinaryFormat: cloudinaryFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryFormat),
      cloudinaryBytes: cloudinaryBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryBytes),
      cloudinaryDurationSeconds:
          cloudinaryDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryDurationSeconds),
      cloudinaryVersion: cloudinaryVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinaryVersion),
      cloudinarySignature: cloudinarySignature == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudinarySignature),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingMediaUpload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMediaUpload(
      attemptPublicId: serializer.fromJson<String>(json['attemptPublicId']),
      pinnedItemPublicId: serializer.fromJson<String>(
        json['pinnedItemPublicId'],
      ),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      mediaPublicId: serializer.fromJson<String?>(json['mediaPublicId']),
      uploadUrl: serializer.fromJson<String?>(json['uploadUrl']),
      uploadUrlExpiresAt: serializer.fromJson<int?>(json['uploadUrlExpiresAt']),
      cloudinaryApiKey: serializer.fromJson<String?>(json['cloudinaryApiKey']),
      cloudinaryTimestamp: serializer.fromJson<String?>(
        json['cloudinaryTimestamp'],
      ),
      cloudinaryUploadSignature: serializer.fromJson<String?>(
        json['cloudinaryUploadSignature'],
      ),
      cloudinaryFolder: serializer.fromJson<String?>(json['cloudinaryFolder']),
      cloudinaryResourceType: serializer.fromJson<String?>(
        json['cloudinaryResourceType'],
      ),
      cloudinaryPublicId: serializer.fromJson<String?>(
        json['cloudinaryPublicId'],
      ),
      cloudinaryAssetId: serializer.fromJson<String?>(
        json['cloudinaryAssetId'],
      ),
      cloudinarySecureUrl: serializer.fromJson<String?>(
        json['cloudinarySecureUrl'],
      ),
      cloudinaryFormat: serializer.fromJson<String?>(json['cloudinaryFormat']),
      cloudinaryBytes: serializer.fromJson<int?>(json['cloudinaryBytes']),
      cloudinaryDurationSeconds: serializer.fromJson<int?>(
        json['cloudinaryDurationSeconds'],
      ),
      cloudinaryVersion: serializer.fromJson<int?>(json['cloudinaryVersion']),
      cloudinarySignature: serializer.fromJson<String?>(
        json['cloudinarySignature'],
      ),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptPublicId': serializer.toJson<String>(attemptPublicId),
      'pinnedItemPublicId': serializer.toJson<String>(pinnedItemPublicId),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'mediaPublicId': serializer.toJson<String?>(mediaPublicId),
      'uploadUrl': serializer.toJson<String?>(uploadUrl),
      'uploadUrlExpiresAt': serializer.toJson<int?>(uploadUrlExpiresAt),
      'cloudinaryApiKey': serializer.toJson<String?>(cloudinaryApiKey),
      'cloudinaryTimestamp': serializer.toJson<String?>(cloudinaryTimestamp),
      'cloudinaryUploadSignature': serializer.toJson<String?>(
        cloudinaryUploadSignature,
      ),
      'cloudinaryFolder': serializer.toJson<String?>(cloudinaryFolder),
      'cloudinaryResourceType': serializer.toJson<String?>(
        cloudinaryResourceType,
      ),
      'cloudinaryPublicId': serializer.toJson<String?>(cloudinaryPublicId),
      'cloudinaryAssetId': serializer.toJson<String?>(cloudinaryAssetId),
      'cloudinarySecureUrl': serializer.toJson<String?>(cloudinarySecureUrl),
      'cloudinaryFormat': serializer.toJson<String?>(cloudinaryFormat),
      'cloudinaryBytes': serializer.toJson<int?>(cloudinaryBytes),
      'cloudinaryDurationSeconds': serializer.toJson<int?>(
        cloudinaryDurationSeconds,
      ),
      'cloudinaryVersion': serializer.toJson<int?>(cloudinaryVersion),
      'cloudinarySignature': serializer.toJson<String?>(cloudinarySignature),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingMediaUpload copyWith({
    String? attemptPublicId,
    String? pinnedItemPublicId,
    String? localFilePath,
    Value<String?> mediaPublicId = const Value.absent(),
    Value<String?> uploadUrl = const Value.absent(),
    Value<int?> uploadUrlExpiresAt = const Value.absent(),
    Value<String?> cloudinaryApiKey = const Value.absent(),
    Value<String?> cloudinaryTimestamp = const Value.absent(),
    Value<String?> cloudinaryUploadSignature = const Value.absent(),
    Value<String?> cloudinaryFolder = const Value.absent(),
    Value<String?> cloudinaryResourceType = const Value.absent(),
    Value<String?> cloudinaryPublicId = const Value.absent(),
    Value<String?> cloudinaryAssetId = const Value.absent(),
    Value<String?> cloudinarySecureUrl = const Value.absent(),
    Value<String?> cloudinaryFormat = const Value.absent(),
    Value<int?> cloudinaryBytes = const Value.absent(),
    Value<int?> cloudinaryDurationSeconds = const Value.absent(),
    Value<int?> cloudinaryVersion = const Value.absent(),
    Value<String?> cloudinarySignature = const Value.absent(),
    String? status,
    Value<String?> lastError = const Value.absent(),
  }) => PendingMediaUpload(
    attemptPublicId: attemptPublicId ?? this.attemptPublicId,
    pinnedItemPublicId: pinnedItemPublicId ?? this.pinnedItemPublicId,
    localFilePath: localFilePath ?? this.localFilePath,
    mediaPublicId: mediaPublicId.present
        ? mediaPublicId.value
        : this.mediaPublicId,
    uploadUrl: uploadUrl.present ? uploadUrl.value : this.uploadUrl,
    uploadUrlExpiresAt: uploadUrlExpiresAt.present
        ? uploadUrlExpiresAt.value
        : this.uploadUrlExpiresAt,
    cloudinaryApiKey: cloudinaryApiKey.present
        ? cloudinaryApiKey.value
        : this.cloudinaryApiKey,
    cloudinaryTimestamp: cloudinaryTimestamp.present
        ? cloudinaryTimestamp.value
        : this.cloudinaryTimestamp,
    cloudinaryUploadSignature: cloudinaryUploadSignature.present
        ? cloudinaryUploadSignature.value
        : this.cloudinaryUploadSignature,
    cloudinaryFolder: cloudinaryFolder.present
        ? cloudinaryFolder.value
        : this.cloudinaryFolder,
    cloudinaryResourceType: cloudinaryResourceType.present
        ? cloudinaryResourceType.value
        : this.cloudinaryResourceType,
    cloudinaryPublicId: cloudinaryPublicId.present
        ? cloudinaryPublicId.value
        : this.cloudinaryPublicId,
    cloudinaryAssetId: cloudinaryAssetId.present
        ? cloudinaryAssetId.value
        : this.cloudinaryAssetId,
    cloudinarySecureUrl: cloudinarySecureUrl.present
        ? cloudinarySecureUrl.value
        : this.cloudinarySecureUrl,
    cloudinaryFormat: cloudinaryFormat.present
        ? cloudinaryFormat.value
        : this.cloudinaryFormat,
    cloudinaryBytes: cloudinaryBytes.present
        ? cloudinaryBytes.value
        : this.cloudinaryBytes,
    cloudinaryDurationSeconds: cloudinaryDurationSeconds.present
        ? cloudinaryDurationSeconds.value
        : this.cloudinaryDurationSeconds,
    cloudinaryVersion: cloudinaryVersion.present
        ? cloudinaryVersion.value
        : this.cloudinaryVersion,
    cloudinarySignature: cloudinarySignature.present
        ? cloudinarySignature.value
        : this.cloudinarySignature,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingMediaUpload copyWithCompanion(PendingMediaUploadTableCompanion data) {
    return PendingMediaUpload(
      attemptPublicId: data.attemptPublicId.present
          ? data.attemptPublicId.value
          : this.attemptPublicId,
      pinnedItemPublicId: data.pinnedItemPublicId.present
          ? data.pinnedItemPublicId.value
          : this.pinnedItemPublicId,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      mediaPublicId: data.mediaPublicId.present
          ? data.mediaPublicId.value
          : this.mediaPublicId,
      uploadUrl: data.uploadUrl.present ? data.uploadUrl.value : this.uploadUrl,
      uploadUrlExpiresAt: data.uploadUrlExpiresAt.present
          ? data.uploadUrlExpiresAt.value
          : this.uploadUrlExpiresAt,
      cloudinaryApiKey: data.cloudinaryApiKey.present
          ? data.cloudinaryApiKey.value
          : this.cloudinaryApiKey,
      cloudinaryTimestamp: data.cloudinaryTimestamp.present
          ? data.cloudinaryTimestamp.value
          : this.cloudinaryTimestamp,
      cloudinaryUploadSignature: data.cloudinaryUploadSignature.present
          ? data.cloudinaryUploadSignature.value
          : this.cloudinaryUploadSignature,
      cloudinaryFolder: data.cloudinaryFolder.present
          ? data.cloudinaryFolder.value
          : this.cloudinaryFolder,
      cloudinaryResourceType: data.cloudinaryResourceType.present
          ? data.cloudinaryResourceType.value
          : this.cloudinaryResourceType,
      cloudinaryPublicId: data.cloudinaryPublicId.present
          ? data.cloudinaryPublicId.value
          : this.cloudinaryPublicId,
      cloudinaryAssetId: data.cloudinaryAssetId.present
          ? data.cloudinaryAssetId.value
          : this.cloudinaryAssetId,
      cloudinarySecureUrl: data.cloudinarySecureUrl.present
          ? data.cloudinarySecureUrl.value
          : this.cloudinarySecureUrl,
      cloudinaryFormat: data.cloudinaryFormat.present
          ? data.cloudinaryFormat.value
          : this.cloudinaryFormat,
      cloudinaryBytes: data.cloudinaryBytes.present
          ? data.cloudinaryBytes.value
          : this.cloudinaryBytes,
      cloudinaryDurationSeconds: data.cloudinaryDurationSeconds.present
          ? data.cloudinaryDurationSeconds.value
          : this.cloudinaryDurationSeconds,
      cloudinaryVersion: data.cloudinaryVersion.present
          ? data.cloudinaryVersion.value
          : this.cloudinaryVersion,
      cloudinarySignature: data.cloudinarySignature.present
          ? data.cloudinarySignature.value
          : this.cloudinarySignature,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMediaUpload(')
          ..write('attemptPublicId: $attemptPublicId, ')
          ..write('pinnedItemPublicId: $pinnedItemPublicId, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('mediaPublicId: $mediaPublicId, ')
          ..write('uploadUrl: $uploadUrl, ')
          ..write('uploadUrlExpiresAt: $uploadUrlExpiresAt, ')
          ..write('cloudinaryApiKey: $cloudinaryApiKey, ')
          ..write('cloudinaryTimestamp: $cloudinaryTimestamp, ')
          ..write('cloudinaryUploadSignature: $cloudinaryUploadSignature, ')
          ..write('cloudinaryFolder: $cloudinaryFolder, ')
          ..write('cloudinaryResourceType: $cloudinaryResourceType, ')
          ..write('cloudinaryPublicId: $cloudinaryPublicId, ')
          ..write('cloudinaryAssetId: $cloudinaryAssetId, ')
          ..write('cloudinarySecureUrl: $cloudinarySecureUrl, ')
          ..write('cloudinaryFormat: $cloudinaryFormat, ')
          ..write('cloudinaryBytes: $cloudinaryBytes, ')
          ..write('cloudinaryDurationSeconds: $cloudinaryDurationSeconds, ')
          ..write('cloudinaryVersion: $cloudinaryVersion, ')
          ..write('cloudinarySignature: $cloudinarySignature, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    attemptPublicId,
    pinnedItemPublicId,
    localFilePath,
    mediaPublicId,
    uploadUrl,
    uploadUrlExpiresAt,
    cloudinaryApiKey,
    cloudinaryTimestamp,
    cloudinaryUploadSignature,
    cloudinaryFolder,
    cloudinaryResourceType,
    cloudinaryPublicId,
    cloudinaryAssetId,
    cloudinarySecureUrl,
    cloudinaryFormat,
    cloudinaryBytes,
    cloudinaryDurationSeconds,
    cloudinaryVersion,
    cloudinarySignature,
    status,
    lastError,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMediaUpload &&
          other.attemptPublicId == this.attemptPublicId &&
          other.pinnedItemPublicId == this.pinnedItemPublicId &&
          other.localFilePath == this.localFilePath &&
          other.mediaPublicId == this.mediaPublicId &&
          other.uploadUrl == this.uploadUrl &&
          other.uploadUrlExpiresAt == this.uploadUrlExpiresAt &&
          other.cloudinaryApiKey == this.cloudinaryApiKey &&
          other.cloudinaryTimestamp == this.cloudinaryTimestamp &&
          other.cloudinaryUploadSignature == this.cloudinaryUploadSignature &&
          other.cloudinaryFolder == this.cloudinaryFolder &&
          other.cloudinaryResourceType == this.cloudinaryResourceType &&
          other.cloudinaryPublicId == this.cloudinaryPublicId &&
          other.cloudinaryAssetId == this.cloudinaryAssetId &&
          other.cloudinarySecureUrl == this.cloudinarySecureUrl &&
          other.cloudinaryFormat == this.cloudinaryFormat &&
          other.cloudinaryBytes == this.cloudinaryBytes &&
          other.cloudinaryDurationSeconds == this.cloudinaryDurationSeconds &&
          other.cloudinaryVersion == this.cloudinaryVersion &&
          other.cloudinarySignature == this.cloudinarySignature &&
          other.status == this.status &&
          other.lastError == this.lastError);
}

class PendingMediaUploadTableCompanion
    extends UpdateCompanion<PendingMediaUpload> {
  final Value<String> attemptPublicId;
  final Value<String> pinnedItemPublicId;
  final Value<String> localFilePath;
  final Value<String?> mediaPublicId;
  final Value<String?> uploadUrl;
  final Value<int?> uploadUrlExpiresAt;
  final Value<String?> cloudinaryApiKey;
  final Value<String?> cloudinaryTimestamp;
  final Value<String?> cloudinaryUploadSignature;
  final Value<String?> cloudinaryFolder;
  final Value<String?> cloudinaryResourceType;
  final Value<String?> cloudinaryPublicId;
  final Value<String?> cloudinaryAssetId;
  final Value<String?> cloudinarySecureUrl;
  final Value<String?> cloudinaryFormat;
  final Value<int?> cloudinaryBytes;
  final Value<int?> cloudinaryDurationSeconds;
  final Value<int?> cloudinaryVersion;
  final Value<String?> cloudinarySignature;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<int> rowid;
  const PendingMediaUploadTableCompanion({
    this.attemptPublicId = const Value.absent(),
    this.pinnedItemPublicId = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.mediaPublicId = const Value.absent(),
    this.uploadUrl = const Value.absent(),
    this.uploadUrlExpiresAt = const Value.absent(),
    this.cloudinaryApiKey = const Value.absent(),
    this.cloudinaryTimestamp = const Value.absent(),
    this.cloudinaryUploadSignature = const Value.absent(),
    this.cloudinaryFolder = const Value.absent(),
    this.cloudinaryResourceType = const Value.absent(),
    this.cloudinaryPublicId = const Value.absent(),
    this.cloudinaryAssetId = const Value.absent(),
    this.cloudinarySecureUrl = const Value.absent(),
    this.cloudinaryFormat = const Value.absent(),
    this.cloudinaryBytes = const Value.absent(),
    this.cloudinaryDurationSeconds = const Value.absent(),
    this.cloudinaryVersion = const Value.absent(),
    this.cloudinarySignature = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMediaUploadTableCompanion.insert({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String localFilePath,
    this.mediaPublicId = const Value.absent(),
    this.uploadUrl = const Value.absent(),
    this.uploadUrlExpiresAt = const Value.absent(),
    this.cloudinaryApiKey = const Value.absent(),
    this.cloudinaryTimestamp = const Value.absent(),
    this.cloudinaryUploadSignature = const Value.absent(),
    this.cloudinaryFolder = const Value.absent(),
    this.cloudinaryResourceType = const Value.absent(),
    this.cloudinaryPublicId = const Value.absent(),
    this.cloudinaryAssetId = const Value.absent(),
    this.cloudinarySecureUrl = const Value.absent(),
    this.cloudinaryFormat = const Value.absent(),
    this.cloudinaryBytes = const Value.absent(),
    this.cloudinaryDurationSeconds = const Value.absent(),
    this.cloudinaryVersion = const Value.absent(),
    this.cloudinarySignature = const Value.absent(),
    required String status,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attemptPublicId = Value(attemptPublicId),
       pinnedItemPublicId = Value(pinnedItemPublicId),
       localFilePath = Value(localFilePath),
       status = Value(status);
  static Insertable<PendingMediaUpload> custom({
    Expression<String>? attemptPublicId,
    Expression<String>? pinnedItemPublicId,
    Expression<String>? localFilePath,
    Expression<String>? mediaPublicId,
    Expression<String>? uploadUrl,
    Expression<int>? uploadUrlExpiresAt,
    Expression<String>? cloudinaryApiKey,
    Expression<String>? cloudinaryTimestamp,
    Expression<String>? cloudinaryUploadSignature,
    Expression<String>? cloudinaryFolder,
    Expression<String>? cloudinaryResourceType,
    Expression<String>? cloudinaryPublicId,
    Expression<String>? cloudinaryAssetId,
    Expression<String>? cloudinarySecureUrl,
    Expression<String>? cloudinaryFormat,
    Expression<int>? cloudinaryBytes,
    Expression<int>? cloudinaryDurationSeconds,
    Expression<int>? cloudinaryVersion,
    Expression<String>? cloudinarySignature,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptPublicId != null) 'attempt_public_id': attemptPublicId,
      if (pinnedItemPublicId != null)
        'pinned_item_public_id': pinnedItemPublicId,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (mediaPublicId != null) 'media_public_id': mediaPublicId,
      if (uploadUrl != null) 'upload_url': uploadUrl,
      if (uploadUrlExpiresAt != null)
        'upload_url_expires_at': uploadUrlExpiresAt,
      if (cloudinaryApiKey != null) 'cloudinary_api_key': cloudinaryApiKey,
      if (cloudinaryTimestamp != null)
        'cloudinary_timestamp': cloudinaryTimestamp,
      if (cloudinaryUploadSignature != null)
        'cloudinary_upload_signature': cloudinaryUploadSignature,
      if (cloudinaryFolder != null) 'cloudinary_folder': cloudinaryFolder,
      if (cloudinaryResourceType != null)
        'cloudinary_resource_type': cloudinaryResourceType,
      if (cloudinaryPublicId != null)
        'cloudinary_public_id': cloudinaryPublicId,
      if (cloudinaryAssetId != null) 'cloudinary_asset_id': cloudinaryAssetId,
      if (cloudinarySecureUrl != null)
        'cloudinary_secure_url': cloudinarySecureUrl,
      if (cloudinaryFormat != null) 'cloudinary_format': cloudinaryFormat,
      if (cloudinaryBytes != null) 'cloudinary_bytes': cloudinaryBytes,
      if (cloudinaryDurationSeconds != null)
        'cloudinary_duration_seconds': cloudinaryDurationSeconds,
      if (cloudinaryVersion != null) 'cloudinary_version': cloudinaryVersion,
      if (cloudinarySignature != null)
        'cloudinary_signature': cloudinarySignature,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMediaUploadTableCompanion copyWith({
    Value<String>? attemptPublicId,
    Value<String>? pinnedItemPublicId,
    Value<String>? localFilePath,
    Value<String?>? mediaPublicId,
    Value<String?>? uploadUrl,
    Value<int?>? uploadUrlExpiresAt,
    Value<String?>? cloudinaryApiKey,
    Value<String?>? cloudinaryTimestamp,
    Value<String?>? cloudinaryUploadSignature,
    Value<String?>? cloudinaryFolder,
    Value<String?>? cloudinaryResourceType,
    Value<String?>? cloudinaryPublicId,
    Value<String?>? cloudinaryAssetId,
    Value<String?>? cloudinarySecureUrl,
    Value<String?>? cloudinaryFormat,
    Value<int?>? cloudinaryBytes,
    Value<int?>? cloudinaryDurationSeconds,
    Value<int?>? cloudinaryVersion,
    Value<String?>? cloudinarySignature,
    Value<String>? status,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return PendingMediaUploadTableCompanion(
      attemptPublicId: attemptPublicId ?? this.attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId ?? this.pinnedItemPublicId,
      localFilePath: localFilePath ?? this.localFilePath,
      mediaPublicId: mediaPublicId ?? this.mediaPublicId,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      uploadUrlExpiresAt: uploadUrlExpiresAt ?? this.uploadUrlExpiresAt,
      cloudinaryApiKey: cloudinaryApiKey ?? this.cloudinaryApiKey,
      cloudinaryTimestamp: cloudinaryTimestamp ?? this.cloudinaryTimestamp,
      cloudinaryUploadSignature:
          cloudinaryUploadSignature ?? this.cloudinaryUploadSignature,
      cloudinaryFolder: cloudinaryFolder ?? this.cloudinaryFolder,
      cloudinaryResourceType:
          cloudinaryResourceType ?? this.cloudinaryResourceType,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      cloudinaryAssetId: cloudinaryAssetId ?? this.cloudinaryAssetId,
      cloudinarySecureUrl: cloudinarySecureUrl ?? this.cloudinarySecureUrl,
      cloudinaryFormat: cloudinaryFormat ?? this.cloudinaryFormat,
      cloudinaryBytes: cloudinaryBytes ?? this.cloudinaryBytes,
      cloudinaryDurationSeconds:
          cloudinaryDurationSeconds ?? this.cloudinaryDurationSeconds,
      cloudinaryVersion: cloudinaryVersion ?? this.cloudinaryVersion,
      cloudinarySignature: cloudinarySignature ?? this.cloudinarySignature,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptPublicId.present) {
      map['attempt_public_id'] = Variable<String>(attemptPublicId.value);
    }
    if (pinnedItemPublicId.present) {
      map['pinned_item_public_id'] = Variable<String>(pinnedItemPublicId.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (mediaPublicId.present) {
      map['media_public_id'] = Variable<String>(mediaPublicId.value);
    }
    if (uploadUrl.present) {
      map['upload_url'] = Variable<String>(uploadUrl.value);
    }
    if (uploadUrlExpiresAt.present) {
      map['upload_url_expires_at'] = Variable<int>(uploadUrlExpiresAt.value);
    }
    if (cloudinaryApiKey.present) {
      map['cloudinary_api_key'] = Variable<String>(cloudinaryApiKey.value);
    }
    if (cloudinaryTimestamp.present) {
      map['cloudinary_timestamp'] = Variable<String>(cloudinaryTimestamp.value);
    }
    if (cloudinaryUploadSignature.present) {
      map['cloudinary_upload_signature'] = Variable<String>(
        cloudinaryUploadSignature.value,
      );
    }
    if (cloudinaryFolder.present) {
      map['cloudinary_folder'] = Variable<String>(cloudinaryFolder.value);
    }
    if (cloudinaryResourceType.present) {
      map['cloudinary_resource_type'] = Variable<String>(
        cloudinaryResourceType.value,
      );
    }
    if (cloudinaryPublicId.present) {
      map['cloudinary_public_id'] = Variable<String>(cloudinaryPublicId.value);
    }
    if (cloudinaryAssetId.present) {
      map['cloudinary_asset_id'] = Variable<String>(cloudinaryAssetId.value);
    }
    if (cloudinarySecureUrl.present) {
      map['cloudinary_secure_url'] = Variable<String>(
        cloudinarySecureUrl.value,
      );
    }
    if (cloudinaryFormat.present) {
      map['cloudinary_format'] = Variable<String>(cloudinaryFormat.value);
    }
    if (cloudinaryBytes.present) {
      map['cloudinary_bytes'] = Variable<int>(cloudinaryBytes.value);
    }
    if (cloudinaryDurationSeconds.present) {
      map['cloudinary_duration_seconds'] = Variable<int>(
        cloudinaryDurationSeconds.value,
      );
    }
    if (cloudinaryVersion.present) {
      map['cloudinary_version'] = Variable<int>(cloudinaryVersion.value);
    }
    if (cloudinarySignature.present) {
      map['cloudinary_signature'] = Variable<String>(cloudinarySignature.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMediaUploadTableCompanion(')
          ..write('attemptPublicId: $attemptPublicId, ')
          ..write('pinnedItemPublicId: $pinnedItemPublicId, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('mediaPublicId: $mediaPublicId, ')
          ..write('uploadUrl: $uploadUrl, ')
          ..write('uploadUrlExpiresAt: $uploadUrlExpiresAt, ')
          ..write('cloudinaryApiKey: $cloudinaryApiKey, ')
          ..write('cloudinaryTimestamp: $cloudinaryTimestamp, ')
          ..write('cloudinaryUploadSignature: $cloudinaryUploadSignature, ')
          ..write('cloudinaryFolder: $cloudinaryFolder, ')
          ..write('cloudinaryResourceType: $cloudinaryResourceType, ')
          ..write('cloudinaryPublicId: $cloudinaryPublicId, ')
          ..write('cloudinaryAssetId: $cloudinaryAssetId, ')
          ..write('cloudinarySecureUrl: $cloudinarySecureUrl, ')
          ..write('cloudinaryFormat: $cloudinaryFormat, ')
          ..write('cloudinaryBytes: $cloudinaryBytes, ')
          ..write('cloudinaryDurationSeconds: $cloudinaryDurationSeconds, ')
          ..write('cloudinaryVersion: $cloudinaryVersion, ')
          ..write('cloudinarySignature: $cloudinarySignature, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalViolationsTableTable extends LocalViolationsTable
    with TableInfo<$LocalViolationsTableTable, LocalViolation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalViolationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _attemptPublicIdMeta = const VerificationMeta(
    'attemptPublicId',
  );
  @override
  late final GeneratedColumn<String> attemptPublicId = GeneratedColumn<String>(
    'attempt_public_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _violationTypeMeta = const VerificationMeta(
    'violationType',
  );
  @override
  late final GeneratedColumn<String> violationType = GeneratedColumn<String>(
    'violation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentMeta = const VerificationMeta('sent');
  @override
  late final GeneratedColumn<bool> sent = GeneratedColumn<bool>(
    'sent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    attemptPublicId,
    violationType,
    severity,
    timestamp,
    metadata,
    sent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_violations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalViolation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('attempt_public_id')) {
      context.handle(
        _attemptPublicIdMeta,
        attemptPublicId.isAcceptableOrUnknown(
          data['attempt_public_id']!,
          _attemptPublicIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptPublicIdMeta);
    }
    if (data.containsKey('violation_type')) {
      context.handle(
        _violationTypeMeta,
        violationType.isAcceptableOrUnknown(
          data['violation_type']!,
          _violationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_violationTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('sent')) {
      context.handle(
        _sentMeta,
        sent.isAcceptableOrUnknown(data['sent']!, _sentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalViolation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalViolation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      attemptPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_public_id'],
      )!,
      violationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}violation_type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      sent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sent'],
      )!,
    );
  }

  @override
  $LocalViolationsTableTable createAlias(String alias) {
    return $LocalViolationsTableTable(attachedDatabase, alias);
  }
}

class LocalViolation extends DataClass implements Insertable<LocalViolation> {
  final int id;

  /// `attempt_public_id` — same opaque id as everywhere else (e.g.
  /// `AnswerOutboxTable.attemptPublicId`); the proctor endpoint already
  /// understands this id and uses it to attribute violations to the
  /// session tab on the proctor dashboard.
  final String attemptPublicId;

  /// Wire string for `ViolationType` (e.g. `LOCKDOWN_FULLSCREEN_EXIT`).
  /// Stored as plain text rather than an enum index so adding a new
  /// violation type to the backend doesn't force a database migration.
  final String violationType;

  /// `WARNING` / `CRITICAL` — same casing the proctor endpoint accepts.
  final String severity;
  final DateTime timestamp;

  /// Free-form JSON envelope for additional context. Nullable for
  /// violation types that have no extra context (`screenshot attempt`
  /// doesn't need anything beyond the fact it happened).
  final String? metadata;

  /// Sync flag. `false` until the violation has been acknowledged by
  /// the backend.
  final bool sent;
  const LocalViolation({
    required this.id,
    required this.attemptPublicId,
    required this.violationType,
    required this.severity,
    required this.timestamp,
    this.metadata,
    required this.sent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['attempt_public_id'] = Variable<String>(attemptPublicId);
    map['violation_type'] = Variable<String>(violationType);
    map['severity'] = Variable<String>(severity);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['sent'] = Variable<bool>(sent);
    return map;
  }

  LocalViolationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalViolationsTableCompanion(
      id: Value(id),
      attemptPublicId: Value(attemptPublicId),
      violationType: Value(violationType),
      severity: Value(severity),
      timestamp: Value(timestamp),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      sent: Value(sent),
    );
  }

  factory LocalViolation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalViolation(
      id: serializer.fromJson<int>(json['id']),
      attemptPublicId: serializer.fromJson<String>(json['attemptPublicId']),
      violationType: serializer.fromJson<String>(json['violationType']),
      severity: serializer.fromJson<String>(json['severity']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      sent: serializer.fromJson<bool>(json['sent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'attemptPublicId': serializer.toJson<String>(attemptPublicId),
      'violationType': serializer.toJson<String>(violationType),
      'severity': serializer.toJson<String>(severity),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'metadata': serializer.toJson<String?>(metadata),
      'sent': serializer.toJson<bool>(sent),
    };
  }

  LocalViolation copyWith({
    int? id,
    String? attemptPublicId,
    String? violationType,
    String? severity,
    DateTime? timestamp,
    Value<String?> metadata = const Value.absent(),
    bool? sent,
  }) => LocalViolation(
    id: id ?? this.id,
    attemptPublicId: attemptPublicId ?? this.attemptPublicId,
    violationType: violationType ?? this.violationType,
    severity: severity ?? this.severity,
    timestamp: timestamp ?? this.timestamp,
    metadata: metadata.present ? metadata.value : this.metadata,
    sent: sent ?? this.sent,
  );
  LocalViolation copyWithCompanion(LocalViolationsTableCompanion data) {
    return LocalViolation(
      id: data.id.present ? data.id.value : this.id,
      attemptPublicId: data.attemptPublicId.present
          ? data.attemptPublicId.value
          : this.attemptPublicId,
      violationType: data.violationType.present
          ? data.violationType.value
          : this.violationType,
      severity: data.severity.present ? data.severity.value : this.severity,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      sent: data.sent.present ? data.sent.value : this.sent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalViolation(')
          ..write('id: $id, ')
          ..write('attemptPublicId: $attemptPublicId, ')
          ..write('violationType: $violationType, ')
          ..write('severity: $severity, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('sent: $sent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    attemptPublicId,
    violationType,
    severity,
    timestamp,
    metadata,
    sent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalViolation &&
          other.id == this.id &&
          other.attemptPublicId == this.attemptPublicId &&
          other.violationType == this.violationType &&
          other.severity == this.severity &&
          other.timestamp == this.timestamp &&
          other.metadata == this.metadata &&
          other.sent == this.sent);
}

class LocalViolationsTableCompanion extends UpdateCompanion<LocalViolation> {
  final Value<int> id;
  final Value<String> attemptPublicId;
  final Value<String> violationType;
  final Value<String> severity;
  final Value<DateTime> timestamp;
  final Value<String?> metadata;
  final Value<bool> sent;
  const LocalViolationsTableCompanion({
    this.id = const Value.absent(),
    this.attemptPublicId = const Value.absent(),
    this.violationType = const Value.absent(),
    this.severity = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.metadata = const Value.absent(),
    this.sent = const Value.absent(),
  });
  LocalViolationsTableCompanion.insert({
    this.id = const Value.absent(),
    required String attemptPublicId,
    required String violationType,
    required String severity,
    required DateTime timestamp,
    this.metadata = const Value.absent(),
    this.sent = const Value.absent(),
  }) : attemptPublicId = Value(attemptPublicId),
       violationType = Value(violationType),
       severity = Value(severity),
       timestamp = Value(timestamp);
  static Insertable<LocalViolation> custom({
    Expression<int>? id,
    Expression<String>? attemptPublicId,
    Expression<String>? violationType,
    Expression<String>? severity,
    Expression<DateTime>? timestamp,
    Expression<String>? metadata,
    Expression<bool>? sent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptPublicId != null) 'attempt_public_id': attemptPublicId,
      if (violationType != null) 'violation_type': violationType,
      if (severity != null) 'severity': severity,
      if (timestamp != null) 'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      if (sent != null) 'sent': sent,
    });
  }

  LocalViolationsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? attemptPublicId,
    Value<String>? violationType,
    Value<String>? severity,
    Value<DateTime>? timestamp,
    Value<String?>? metadata,
    Value<bool>? sent,
  }) {
    return LocalViolationsTableCompanion(
      id: id ?? this.id,
      attemptPublicId: attemptPublicId ?? this.attemptPublicId,
      violationType: violationType ?? this.violationType,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      sent: sent ?? this.sent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (attemptPublicId.present) {
      map['attempt_public_id'] = Variable<String>(attemptPublicId.value);
    }
    if (violationType.present) {
      map['violation_type'] = Variable<String>(violationType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (sent.present) {
      map['sent'] = Variable<bool>(sent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalViolationsTableCompanion(')
          ..write('id: $id, ')
          ..write('attemptPublicId: $attemptPublicId, ')
          ..write('violationType: $violationType, ')
          ..write('severity: $severity, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('sent: $sent')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnswerOutboxTableTable answerOutboxTable =
      $AnswerOutboxTableTable(this);
  late final $PendingMediaUploadTableTable pendingMediaUploadTable =
      $PendingMediaUploadTableTable(this);
  late final $LocalViolationsTableTable localViolationsTable =
      $LocalViolationsTableTable(this);
  late final AnswerOutboxDao answerOutboxDao = AnswerOutboxDao(
    this as AppDatabase,
  );
  late final PendingMediaUploadDao pendingMediaUploadDao =
      PendingMediaUploadDao(this as AppDatabase);
  late final LocalViolationDao localViolationDao = LocalViolationDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    answerOutboxTable,
    pendingMediaUploadTable,
    localViolationsTable,
  ];
}

typedef $$AnswerOutboxTableTableCreateCompanionBuilder =
    AnswerOutboxTableCompanion Function({
      required String attemptPublicId,
      required String pinnedItemPublicId,
      required String payload,
      required String status,
      Value<String?> lastSyncError,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AnswerOutboxTableTableUpdateCompanionBuilder =
    AnswerOutboxTableCompanion Function({
      Value<String> attemptPublicId,
      Value<String> pinnedItemPublicId,
      Value<String> payload,
      Value<String> status,
      Value<String?> lastSyncError,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AnswerOutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $AnswerOutboxTableTable> {
  $$AnswerOutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinnedItemPublicId => $composableBuilder(
    column: $table.pinnedItemPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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
}

class $$AnswerOutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AnswerOutboxTableTable> {
  $$AnswerOutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinnedItemPublicId => $composableBuilder(
    column: $table.pinnedItemPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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
}

class $$AnswerOutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnswerOutboxTableTable> {
  $$AnswerOutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinnedItemPublicId => $composableBuilder(
    column: $table.pinnedItemPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AnswerOutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnswerOutboxTableTable,
          AnswerOutbox,
          $$AnswerOutboxTableTableFilterComposer,
          $$AnswerOutboxTableTableOrderingComposer,
          $$AnswerOutboxTableTableAnnotationComposer,
          $$AnswerOutboxTableTableCreateCompanionBuilder,
          $$AnswerOutboxTableTableUpdateCompanionBuilder,
          (
            AnswerOutbox,
            BaseReferences<
              _$AppDatabase,
              $AnswerOutboxTableTable,
              AnswerOutbox
            >,
          ),
          AnswerOutbox,
          PrefetchHooks Function()
        > {
  $$AnswerOutboxTableTableTableManager(
    _$AppDatabase db,
    $AnswerOutboxTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerOutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerOutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerOutboxTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> attemptPublicId = const Value.absent(),
                Value<String> pinnedItemPublicId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnswerOutboxTableCompanion(
                attemptPublicId: attemptPublicId,
                pinnedItemPublicId: pinnedItemPublicId,
                payload: payload,
                status: status,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attemptPublicId,
                required String pinnedItemPublicId,
                required String payload,
                required String status,
                Value<String?> lastSyncError = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AnswerOutboxTableCompanion.insert(
                attemptPublicId: attemptPublicId,
                pinnedItemPublicId: pinnedItemPublicId,
                payload: payload,
                status: status,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnswerOutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnswerOutboxTableTable,
      AnswerOutbox,
      $$AnswerOutboxTableTableFilterComposer,
      $$AnswerOutboxTableTableOrderingComposer,
      $$AnswerOutboxTableTableAnnotationComposer,
      $$AnswerOutboxTableTableCreateCompanionBuilder,
      $$AnswerOutboxTableTableUpdateCompanionBuilder,
      (
        AnswerOutbox,
        BaseReferences<_$AppDatabase, $AnswerOutboxTableTable, AnswerOutbox>,
      ),
      AnswerOutbox,
      PrefetchHooks Function()
    >;
typedef $$PendingMediaUploadTableTableCreateCompanionBuilder =
    PendingMediaUploadTableCompanion Function({
      required String attemptPublicId,
      required String pinnedItemPublicId,
      required String localFilePath,
      Value<String?> mediaPublicId,
      Value<String?> uploadUrl,
      Value<int?> uploadUrlExpiresAt,
      Value<String?> cloudinaryApiKey,
      Value<String?> cloudinaryTimestamp,
      Value<String?> cloudinaryUploadSignature,
      Value<String?> cloudinaryFolder,
      Value<String?> cloudinaryResourceType,
      Value<String?> cloudinaryPublicId,
      Value<String?> cloudinaryAssetId,
      Value<String?> cloudinarySecureUrl,
      Value<String?> cloudinaryFormat,
      Value<int?> cloudinaryBytes,
      Value<int?> cloudinaryDurationSeconds,
      Value<int?> cloudinaryVersion,
      Value<String?> cloudinarySignature,
      required String status,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$PendingMediaUploadTableTableUpdateCompanionBuilder =
    PendingMediaUploadTableCompanion Function({
      Value<String> attemptPublicId,
      Value<String> pinnedItemPublicId,
      Value<String> localFilePath,
      Value<String?> mediaPublicId,
      Value<String?> uploadUrl,
      Value<int?> uploadUrlExpiresAt,
      Value<String?> cloudinaryApiKey,
      Value<String?> cloudinaryTimestamp,
      Value<String?> cloudinaryUploadSignature,
      Value<String?> cloudinaryFolder,
      Value<String?> cloudinaryResourceType,
      Value<String?> cloudinaryPublicId,
      Value<String?> cloudinaryAssetId,
      Value<String?> cloudinarySecureUrl,
      Value<String?> cloudinaryFormat,
      Value<int?> cloudinaryBytes,
      Value<int?> cloudinaryDurationSeconds,
      Value<int?> cloudinaryVersion,
      Value<String?> cloudinarySignature,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$PendingMediaUploadTableTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMediaUploadTableTable> {
  $$PendingMediaUploadTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinnedItemPublicId => $composableBuilder(
    column: $table.pinnedItemPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaPublicId => $composableBuilder(
    column: $table.mediaPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadUrl => $composableBuilder(
    column: $table.uploadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uploadUrlExpiresAt => $composableBuilder(
    column: $table.uploadUrlExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryApiKey => $composableBuilder(
    column: $table.cloudinaryApiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryTimestamp => $composableBuilder(
    column: $table.cloudinaryTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryUploadSignature => $composableBuilder(
    column: $table.cloudinaryUploadSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryFolder => $composableBuilder(
    column: $table.cloudinaryFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryResourceType => $composableBuilder(
    column: $table.cloudinaryResourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryPublicId => $composableBuilder(
    column: $table.cloudinaryPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryAssetId => $composableBuilder(
    column: $table.cloudinaryAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinarySecureUrl => $composableBuilder(
    column: $table.cloudinarySecureUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinaryFormat => $composableBuilder(
    column: $table.cloudinaryFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudinaryBytes => $composableBuilder(
    column: $table.cloudinaryBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudinaryDurationSeconds => $composableBuilder(
    column: $table.cloudinaryDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudinaryVersion => $composableBuilder(
    column: $table.cloudinaryVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudinarySignature => $composableBuilder(
    column: $table.cloudinarySignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMediaUploadTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMediaUploadTableTable> {
  $$PendingMediaUploadTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinnedItemPublicId => $composableBuilder(
    column: $table.pinnedItemPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaPublicId => $composableBuilder(
    column: $table.mediaPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadUrl => $composableBuilder(
    column: $table.uploadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadUrlExpiresAt => $composableBuilder(
    column: $table.uploadUrlExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryApiKey => $composableBuilder(
    column: $table.cloudinaryApiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryTimestamp => $composableBuilder(
    column: $table.cloudinaryTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryUploadSignature => $composableBuilder(
    column: $table.cloudinaryUploadSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryFolder => $composableBuilder(
    column: $table.cloudinaryFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryResourceType => $composableBuilder(
    column: $table.cloudinaryResourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryPublicId => $composableBuilder(
    column: $table.cloudinaryPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryAssetId => $composableBuilder(
    column: $table.cloudinaryAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinarySecureUrl => $composableBuilder(
    column: $table.cloudinarySecureUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinaryFormat => $composableBuilder(
    column: $table.cloudinaryFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudinaryBytes => $composableBuilder(
    column: $table.cloudinaryBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudinaryDurationSeconds => $composableBuilder(
    column: $table.cloudinaryDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudinaryVersion => $composableBuilder(
    column: $table.cloudinaryVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudinarySignature => $composableBuilder(
    column: $table.cloudinarySignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMediaUploadTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMediaUploadTableTable> {
  $$PendingMediaUploadTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinnedItemPublicId => $composableBuilder(
    column: $table.pinnedItemPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaPublicId => $composableBuilder(
    column: $table.mediaPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadUrl =>
      $composableBuilder(column: $table.uploadUrl, builder: (column) => column);

  GeneratedColumn<int> get uploadUrlExpiresAt => $composableBuilder(
    column: $table.uploadUrlExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryApiKey => $composableBuilder(
    column: $table.cloudinaryApiKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryTimestamp => $composableBuilder(
    column: $table.cloudinaryTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryUploadSignature => $composableBuilder(
    column: $table.cloudinaryUploadSignature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryFolder => $composableBuilder(
    column: $table.cloudinaryFolder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryResourceType => $composableBuilder(
    column: $table.cloudinaryResourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryPublicId => $composableBuilder(
    column: $table.cloudinaryPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryAssetId => $composableBuilder(
    column: $table.cloudinaryAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinarySecureUrl => $composableBuilder(
    column: $table.cloudinarySecureUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinaryFormat => $composableBuilder(
    column: $table.cloudinaryFormat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudinaryBytes => $composableBuilder(
    column: $table.cloudinaryBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudinaryDurationSeconds => $composableBuilder(
    column: $table.cloudinaryDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudinaryVersion => $composableBuilder(
    column: $table.cloudinaryVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudinarySignature => $composableBuilder(
    column: $table.cloudinarySignature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingMediaUploadTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMediaUploadTableTable,
          PendingMediaUpload,
          $$PendingMediaUploadTableTableFilterComposer,
          $$PendingMediaUploadTableTableOrderingComposer,
          $$PendingMediaUploadTableTableAnnotationComposer,
          $$PendingMediaUploadTableTableCreateCompanionBuilder,
          $$PendingMediaUploadTableTableUpdateCompanionBuilder,
          (
            PendingMediaUpload,
            BaseReferences<
              _$AppDatabase,
              $PendingMediaUploadTableTable,
              PendingMediaUpload
            >,
          ),
          PendingMediaUpload,
          PrefetchHooks Function()
        > {
  $$PendingMediaUploadTableTableTableManager(
    _$AppDatabase db,
    $PendingMediaUploadTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMediaUploadTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingMediaUploadTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingMediaUploadTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> attemptPublicId = const Value.absent(),
                Value<String> pinnedItemPublicId = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<String?> mediaPublicId = const Value.absent(),
                Value<String?> uploadUrl = const Value.absent(),
                Value<int?> uploadUrlExpiresAt = const Value.absent(),
                Value<String?> cloudinaryApiKey = const Value.absent(),
                Value<String?> cloudinaryTimestamp = const Value.absent(),
                Value<String?> cloudinaryUploadSignature = const Value.absent(),
                Value<String?> cloudinaryFolder = const Value.absent(),
                Value<String?> cloudinaryResourceType = const Value.absent(),
                Value<String?> cloudinaryPublicId = const Value.absent(),
                Value<String?> cloudinaryAssetId = const Value.absent(),
                Value<String?> cloudinarySecureUrl = const Value.absent(),
                Value<String?> cloudinaryFormat = const Value.absent(),
                Value<int?> cloudinaryBytes = const Value.absent(),
                Value<int?> cloudinaryDurationSeconds = const Value.absent(),
                Value<int?> cloudinaryVersion = const Value.absent(),
                Value<String?> cloudinarySignature = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMediaUploadTableCompanion(
                attemptPublicId: attemptPublicId,
                pinnedItemPublicId: pinnedItemPublicId,
                localFilePath: localFilePath,
                mediaPublicId: mediaPublicId,
                uploadUrl: uploadUrl,
                uploadUrlExpiresAt: uploadUrlExpiresAt,
                cloudinaryApiKey: cloudinaryApiKey,
                cloudinaryTimestamp: cloudinaryTimestamp,
                cloudinaryUploadSignature: cloudinaryUploadSignature,
                cloudinaryFolder: cloudinaryFolder,
                cloudinaryResourceType: cloudinaryResourceType,
                cloudinaryPublicId: cloudinaryPublicId,
                cloudinaryAssetId: cloudinaryAssetId,
                cloudinarySecureUrl: cloudinarySecureUrl,
                cloudinaryFormat: cloudinaryFormat,
                cloudinaryBytes: cloudinaryBytes,
                cloudinaryDurationSeconds: cloudinaryDurationSeconds,
                cloudinaryVersion: cloudinaryVersion,
                cloudinarySignature: cloudinarySignature,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attemptPublicId,
                required String pinnedItemPublicId,
                required String localFilePath,
                Value<String?> mediaPublicId = const Value.absent(),
                Value<String?> uploadUrl = const Value.absent(),
                Value<int?> uploadUrlExpiresAt = const Value.absent(),
                Value<String?> cloudinaryApiKey = const Value.absent(),
                Value<String?> cloudinaryTimestamp = const Value.absent(),
                Value<String?> cloudinaryUploadSignature = const Value.absent(),
                Value<String?> cloudinaryFolder = const Value.absent(),
                Value<String?> cloudinaryResourceType = const Value.absent(),
                Value<String?> cloudinaryPublicId = const Value.absent(),
                Value<String?> cloudinaryAssetId = const Value.absent(),
                Value<String?> cloudinarySecureUrl = const Value.absent(),
                Value<String?> cloudinaryFormat = const Value.absent(),
                Value<int?> cloudinaryBytes = const Value.absent(),
                Value<int?> cloudinaryDurationSeconds = const Value.absent(),
                Value<int?> cloudinaryVersion = const Value.absent(),
                Value<String?> cloudinarySignature = const Value.absent(),
                required String status,
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMediaUploadTableCompanion.insert(
                attemptPublicId: attemptPublicId,
                pinnedItemPublicId: pinnedItemPublicId,
                localFilePath: localFilePath,
                mediaPublicId: mediaPublicId,
                uploadUrl: uploadUrl,
                uploadUrlExpiresAt: uploadUrlExpiresAt,
                cloudinaryApiKey: cloudinaryApiKey,
                cloudinaryTimestamp: cloudinaryTimestamp,
                cloudinaryUploadSignature: cloudinaryUploadSignature,
                cloudinaryFolder: cloudinaryFolder,
                cloudinaryResourceType: cloudinaryResourceType,
                cloudinaryPublicId: cloudinaryPublicId,
                cloudinaryAssetId: cloudinaryAssetId,
                cloudinarySecureUrl: cloudinarySecureUrl,
                cloudinaryFormat: cloudinaryFormat,
                cloudinaryBytes: cloudinaryBytes,
                cloudinaryDurationSeconds: cloudinaryDurationSeconds,
                cloudinaryVersion: cloudinaryVersion,
                cloudinarySignature: cloudinarySignature,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMediaUploadTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMediaUploadTableTable,
      PendingMediaUpload,
      $$PendingMediaUploadTableTableFilterComposer,
      $$PendingMediaUploadTableTableOrderingComposer,
      $$PendingMediaUploadTableTableAnnotationComposer,
      $$PendingMediaUploadTableTableCreateCompanionBuilder,
      $$PendingMediaUploadTableTableUpdateCompanionBuilder,
      (
        PendingMediaUpload,
        BaseReferences<
          _$AppDatabase,
          $PendingMediaUploadTableTable,
          PendingMediaUpload
        >,
      ),
      PendingMediaUpload,
      PrefetchHooks Function()
    >;
typedef $$LocalViolationsTableTableCreateCompanionBuilder =
    LocalViolationsTableCompanion Function({
      Value<int> id,
      required String attemptPublicId,
      required String violationType,
      required String severity,
      required DateTime timestamp,
      Value<String?> metadata,
      Value<bool> sent,
    });
typedef $$LocalViolationsTableTableUpdateCompanionBuilder =
    LocalViolationsTableCompanion Function({
      Value<int> id,
      Value<String> attemptPublicId,
      Value<String> violationType,
      Value<String> severity,
      Value<DateTime> timestamp,
      Value<String?> metadata,
      Value<bool> sent,
    });

class $$LocalViolationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalViolationsTableTable> {
  $$LocalViolationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get violationType => $composableBuilder(
    column: $table.violationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sent => $composableBuilder(
    column: $table.sent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalViolationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalViolationsTableTable> {
  $$LocalViolationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get violationType => $composableBuilder(
    column: $table.violationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sent => $composableBuilder(
    column: $table.sent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalViolationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalViolationsTableTable> {
  $$LocalViolationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get attemptPublicId => $composableBuilder(
    column: $table.attemptPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get violationType => $composableBuilder(
    column: $table.violationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<bool> get sent =>
      $composableBuilder(column: $table.sent, builder: (column) => column);
}

class $$LocalViolationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalViolationsTableTable,
          LocalViolation,
          $$LocalViolationsTableTableFilterComposer,
          $$LocalViolationsTableTableOrderingComposer,
          $$LocalViolationsTableTableAnnotationComposer,
          $$LocalViolationsTableTableCreateCompanionBuilder,
          $$LocalViolationsTableTableUpdateCompanionBuilder,
          (
            LocalViolation,
            BaseReferences<
              _$AppDatabase,
              $LocalViolationsTableTable,
              LocalViolation
            >,
          ),
          LocalViolation,
          PrefetchHooks Function()
        > {
  $$LocalViolationsTableTableTableManager(
    _$AppDatabase db,
    $LocalViolationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalViolationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalViolationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalViolationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> attemptPublicId = const Value.absent(),
                Value<String> violationType = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> sent = const Value.absent(),
              }) => LocalViolationsTableCompanion(
                id: id,
                attemptPublicId: attemptPublicId,
                violationType: violationType,
                severity: severity,
                timestamp: timestamp,
                metadata: metadata,
                sent: sent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String attemptPublicId,
                required String violationType,
                required String severity,
                required DateTime timestamp,
                Value<String?> metadata = const Value.absent(),
                Value<bool> sent = const Value.absent(),
              }) => LocalViolationsTableCompanion.insert(
                id: id,
                attemptPublicId: attemptPublicId,
                violationType: violationType,
                severity: severity,
                timestamp: timestamp,
                metadata: metadata,
                sent: sent,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalViolationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalViolationsTableTable,
      LocalViolation,
      $$LocalViolationsTableTableFilterComposer,
      $$LocalViolationsTableTableOrderingComposer,
      $$LocalViolationsTableTableAnnotationComposer,
      $$LocalViolationsTableTableCreateCompanionBuilder,
      $$LocalViolationsTableTableUpdateCompanionBuilder,
      (
        LocalViolation,
        BaseReferences<
          _$AppDatabase,
          $LocalViolationsTableTable,
          LocalViolation
        >,
      ),
      LocalViolation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnswerOutboxTableTableTableManager get answerOutboxTable =>
      $$AnswerOutboxTableTableTableManager(_db, _db.answerOutboxTable);
  $$PendingMediaUploadTableTableTableManager get pendingMediaUploadTable =>
      $$PendingMediaUploadTableTableTableManager(
        _db,
        _db.pendingMediaUploadTable,
      );
  $$LocalViolationsTableTableTableManager get localViolationsTable =>
      $$LocalViolationsTableTableTableManager(_db, _db.localViolationsTable);
}
