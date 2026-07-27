// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$AnswerOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $AnswerOutboxTableTable get answerOutboxTable =>
      attachedDatabase.answerOutboxTable;
  AnswerOutboxDaoManager get managers => AnswerOutboxDaoManager(this);
}

class AnswerOutboxDaoManager {
  final _$AnswerOutboxDaoMixin _db;
  AnswerOutboxDaoManager(this._db);
  $$AnswerOutboxTableTableTableManager get answerOutboxTable =>
      $$AnswerOutboxTableTableTableManager(
        _db.attachedDatabase,
        _db.answerOutboxTable,
      );
}
