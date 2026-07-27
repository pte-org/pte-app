import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';

void main() {
  test(
    'a real file-backed outbox row survives destroying and reconstructing the database instance '
    '(process-death survival, the core reliability property of this phase)',
    () async {
      final dir = await Directory.systemTemp.createTemp('pte_app_db_test');
      final dbFile = File(p.join(dir.path, 'test.sqlite'));
      addTearDown(() async {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      final firstInstance = AppDatabase(NativeDatabase(dbFile));
      await firstInstance.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        payload: 'survives restart',
      );
      await firstInstance.close();

      final secondInstance = AppDatabase(NativeDatabase(dbFile));
      final rows = await secondInstance.answerOutboxDao.queryByAttempt('attempt-1');
      await secondInstance.close();

      expect(rows, hasLength(1));
      expect(rows.single.payload, 'survives restart');
      expect(rows.single.status, AnswerSyncStatus.pending.name);
    },
  );
}
