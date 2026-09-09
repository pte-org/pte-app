// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_violation_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalViolationDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalViolationsTableTable get localViolationsTable =>
      attachedDatabase.localViolationsTable;
  LocalViolationDaoManager get managers => LocalViolationDaoManager(this);
}

class LocalViolationDaoManager {
  final _$LocalViolationDaoMixin _db;
  LocalViolationDaoManager(this._db);
  $$LocalViolationsTableTableTableManager get localViolationsTable =>
      $$LocalViolationsTableTableTableManager(
        _db.attachedDatabase,
        _db.localViolationsTable,
      );
}
