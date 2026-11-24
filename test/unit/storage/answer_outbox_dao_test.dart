import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'upsertAnswer is idempotent — two upserts for the same key leave exactly one row with the latest payload',
    () async {
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'first',
      );
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'second',
      );

      final rows = await db.answerOutboxDao.queryByAttempt('a1');

      expect(rows, hasLength(1));
      expect(rows.single.payload, 'second');
    },
  );

  test(
    'a fresh local edit via upsertAnswer resets a terminalRejected row back to pending',
    () async {
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'first',
      );
      await db.answerOutboxDao.markTerminalRejected(
        'a1',
        'p1',
        'NOT_CURRENT_TASK',
      );
      var row = (await db.answerOutboxDao.queryByAttempt('a1')).single;
      expect(row.status, AnswerSyncStatus.terminalRejected.name);

      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'edited',
      );

      row = (await db.answerOutboxDao.queryByAttempt('a1')).single;
      expect(row.status, AnswerSyncStatus.pending.name);
      expect(row.payload, 'edited');
    },
  );

  test(
    'markSyncedIfUnchanged leaves a row pending when a newer payload replaced the one that was sent',
    () async {
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: '',
      );
      // The real answer lands while the blank request is still in flight.
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'media-1',
      );

      await db.answerOutboxDao.markSyncedIfUnchanged('a1', 'p1', '');

      final row = (await db.answerOutboxDao.queryByAttempt('a1')).single;
      expect(row.status, AnswerSyncStatus.pending.name);
      expect(row.payload, 'media-1');
    },
  );

  test(
    'markSyncedIfUnchanged marks a row synced when the payload matches',
    () async {
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'x',
      );

      await db.answerOutboxDao.markSyncedIfUnchanged('a1', 'p1', 'x');

      final row = (await db.answerOutboxDao.queryByAttempt('a1')).single;
      expect(row.status, AnswerSyncStatus.synced.name);
    },
  );

  test(
    'queryPendingByAttempt returns only pending rows, never synced/terminalRejected ones',
    () async {
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'pending-1',
        payload: 'x',
      );
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'synced-1',
        payload: 'x',
      );
      await db.answerOutboxDao.markSyncedIfUnchanged('a1', 'synced-1', 'x');
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'rejected-1',
        payload: 'x',
      );
      await db.answerOutboxDao.markTerminalRejected(
        'a1',
        'rejected-1',
        'ANSWER_ALREADY_SUBMITTED',
      );

      final pending = await db.answerOutboxDao.queryPendingByAttempt('a1');

      expect(pending.map((r) => r.pinnedItemPublicId), ['pending-1']);
    },
  );

  test(
    'queryByAttempt never returns rows for a different attemptPublicId',
    () async {
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        payload: 'x',
      );
      await db.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'a2',
        pinnedItemPublicId: 'p1',
        payload: 'y',
      );

      final rows = await db.answerOutboxDao.queryByAttempt('a1');

      expect(rows, hasLength(1));
      expect(rows.single.attemptPublicId, 'a1');
    },
  );
}
