// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_media_upload_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingMediaUploadDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingMediaUploadTableTable get pendingMediaUploadTable =>
      attachedDatabase.pendingMediaUploadTable;
  PendingMediaUploadDaoManager get managers =>
      PendingMediaUploadDaoManager(this);
}

class PendingMediaUploadDaoManager {
  final _$PendingMediaUploadDaoMixin _db;
  PendingMediaUploadDaoManager(this._db);
  $$PendingMediaUploadTableTableTableManager get pendingMediaUploadTable =>
      $$PendingMediaUploadTableTableTableManager(
        _db.attachedDatabase,
        _db.pendingMediaUploadTable,
      );
}
