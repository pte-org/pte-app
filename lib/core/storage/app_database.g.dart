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
  final String status;
  final String? lastError;
  const PendingMediaUpload({
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required this.localFilePath,
    this.mediaPublicId,
    this.uploadUrl,
    this.uploadUrlExpiresAt,
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
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attemptPublicId,
    pinnedItemPublicId,
    localFilePath,
    mediaPublicId,
    uploadUrl,
    uploadUrlExpiresAt,
    status,
    lastError,
  );
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
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
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
  late final AnswerOutboxDao answerOutboxDao = AnswerOutboxDao(
    this as AppDatabase,
  );
  late final PendingMediaUploadDao pendingMediaUploadDao =
      PendingMediaUploadDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    answerOutboxTable,
    pendingMediaUploadTable,
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
}
