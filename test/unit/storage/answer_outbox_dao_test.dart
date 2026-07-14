import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:aptis_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:aptis_app/core/storage/drift_database.dart';
import 'package:aptis_app/core/storage/models/answer_sync_status.dart';

void main() {
  group('AnswerOutboxDao', () {
    test(
      'upsertAnswer is idempotent: same (attemptId, questionId) twice keeps one row with latest content',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final dao = AnswerOutboxDao(db);

        await dao.upsertAnswer(
          attemptId: 'a1',
          questionId: 'q1',
          content: 'first answer',
        );
        await dao.upsertAnswer(
          attemptId: 'a1',
          questionId: 'q1',
          content: 'changed answer',
        );

        final rows = await dao.queryByAttemptId('a1');
        expect(rows, hasLength(1));
        expect(rows.single.content, 'changed answer');

        await db.close();
      },
    );

    test(
      'queryPendingByAttemptId only returns pending rows for the given attemptId',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final dao = AnswerOutboxDao(db);

        await dao.upsertAnswer(
          attemptId: 'a1',
          questionId: 'q1',
          content: 'ans-1',
        );
        await dao.upsertAnswer(
          attemptId: 'a1',
          questionId: 'q2',
          content: 'ans-2',
        );
        await dao.upsertAnswer(
          attemptId: 'a2',
          questionId: 'q1',
          content: 'other attempt',
        );

        final pending = await dao.queryPendingByAttemptId('a1');
        expect(pending, hasLength(2));
        expect(
          pending.every((r) => r.status == AnswerSyncStatus.pending.name),
          isTrue,
        );

        await db.close();
      },
    );

    test(
      'markSynced transitions status so the row no longer appears as pending',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final dao = AnswerOutboxDao(db);

        await dao.upsertAnswer(
          attemptId: 'a1',
          questionId: 'q1',
          content: 'ans-1',
        );
        await dao.markSynced('a1', 'q1');

        final pending = await dao.queryPendingByAttemptId('a1');
        expect(pending, isEmpty);

        await db.close();
      },
    );

    test('markFailed records the failure reason', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = AnswerOutboxDao(db);

      await dao.upsertAnswer(
        attemptId: 'a1',
        questionId: 'q1',
        content: 'ans-1',
      );
      await dao.markFailed('a1', 'q1', 'part closed');

      final rows = await dao.queryByAttemptId('a1');
      expect(rows.single.status, AnswerSyncStatus.failed.name);
      expect(rows.single.lastSyncError, 'part closed');

      await db.close();
    });

    test(
      'answers survive reopening AppDatabase against the same on-disk file',
      () async {
        final dir = await Directory.systemTemp.createTemp('aptis_outbox_test');
        final dbFile = File(p.join(dir.path, 'outbox.sqlite'));

        final firstDb = AppDatabase(NativeDatabase(dbFile));
        final firstDao = AnswerOutboxDao(firstDb);
        await firstDao.upsertAnswer(
          attemptId: 'a1',
          questionId: 'q1',
          content: 'still here',
        );
        await firstDb.close();

        final secondDb = AppDatabase(NativeDatabase(dbFile));
        final secondDao = AnswerOutboxDao(secondDb);
        final rows = await secondDao.queryByAttemptId('a1');
        expect(rows, hasLength(1));
        expect(rows.single.content, 'still here');

        await secondDb.close();
        await dir.delete(recursive: true);
      },
    );
  });
}
