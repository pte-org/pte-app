import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aptis_app/core/network/api_client.dart';
import 'package:aptis_app/core/network/api_exceptions.dart';
import 'package:aptis_app/core/network/models/answer_submit_response.dart';
import 'package:aptis_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:aptis_app/core/storage/drift_database.dart';
import 'package:aptis_app/core/storage/models/answer_sync_status.dart';
import 'package:aptis_app/core/sync/network_canary.dart';
import 'package:aptis_app/core/sync/sync_engine.dart';

/// Hand-written fake `ApiClient` — overrides only [submitAnswers], routing
/// it (and the idempotency key it was called with) to a per-test handler.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._handler) : super(Dio());

  final Future<AnswerSubmitResponse> Function(
    String attemptId,
    Map<String, dynamic> answers,
    String? idempotencyKey,
  )
  _handler;

  @override
  Future<AnswerSubmitResponse> submitAnswers(
    String attemptId,
    Map<String, dynamic> answers, {
    String? idempotencyKey,
  }) => _handler(attemptId, answers, idempotencyKey);
}

/// Records when the pending-answers read completes, so the test can prove
/// the read finished (and any underlying transaction was released) before
/// the first network call starts — the WAL short-read-transaction pattern
/// from Phase 2's risk mitigation.
class _RecordingDao extends AnswerOutboxDao {
  _RecordingDao(super.db, this.events);

  final List<String> events;

  @override
  Future<List<AnswerOutbox>> queryPendingByAttemptId(String attemptId) async {
    final result = await super.queryPendingByAttemptId(attemptId);
    events.add('query_complete');
    return result;
  }
}

void main() {
  group('SyncEngine', () {
    late AppDatabase db;
    late AnswerOutboxDao dao;
    late StreamController<void> canaryController;
    late NetworkCanary canary;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = AnswerOutboxDao(db);
      canaryController = StreamController<void>.broadcast();
      canary = NetworkCanary(availableStream: canaryController.stream);
    });

    tearDown(() async {
      await canaryController.close();
      await db.close();
    });

    test(
      'on canary available, each pending answer is POSTed once with an Idempotency-Key',
      () async {
        await dao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'q1',
          content: 'answer-1',
        );
        await dao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'q2',
          content: 'answer-2',
        );
        await dao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'q3',
          content: 'answer-3',
        );

        final calls = <String?>[];
        final apiClient = _FakeApiClient((
          attemptId,
          answers,
          idempotencyKey,
        ) async {
          calls.add(idempotencyKey);
          return AnswerSubmitResponse(
            questionId: answers['question_id'] as String,
            acceptedAt: DateTime.utc(2026),
          );
        });

        final engine = SyncEngine(
          outboxDao: dao,
          apiClient: apiClient,
          canary: canary,
        );
        engine.startSync('attempt-1');

        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(calls.length, 3);
        expect(calls.toSet(), {'attempt-1#q1', 'attempt-1#q2', 'attempt-1#q3'});

        engine.stopSync();
      },
    );

    test(
      '200 marks synced, 409 marks failed (excluded from next flush), timeout stays pending and retries',
      () async {
        await dao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'ok',
          content: 'a',
        );
        await dao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'closed',
          content: 'b',
        );
        await dao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'flaky',
          content: 'c',
        );

        var flakyCallCount = 0;
        final apiClient = _FakeApiClient((
          attemptId,
          answers,
          idempotencyKey,
        ) async {
          final questionId = answers['question_id'] as String;
          switch (questionId) {
            case 'ok':
              return AnswerSubmitResponse(
                questionId: questionId,
                acceptedAt: DateTime.utc(2026),
              );
            case 'closed':
              throw const ConflictException();
            case 'flaky':
              flakyCallCount++;
              throw const NetworkException();
            default:
              throw StateError('unexpected questionId $questionId');
          }
        });

        final engine = SyncEngine(
          outboxDao: dao,
          apiClient: apiClient,
          canary: canary,
        );
        engine.startSync('attempt-1');

        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final rows = await dao.queryByAttemptId('attempt-1');
        final byQuestion = {for (final row in rows) row.questionId: row};

        expect(byQuestion['ok']!.status, AnswerSyncStatus.synced.name);
        expect(byQuestion['closed']!.status, AnswerSyncStatus.failed.name);
        expect(byQuestion['closed']!.lastSyncError, 'part closed');
        expect(byQuestion['flaky']!.status, AnswerSyncStatus.pending.name);

        final stillPending = await dao.queryPendingByAttemptId('attempt-1');
        expect(stillPending.map((row) => row.questionId), ['flaky']);

        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(flakyCallCount, 2);

        engine.stopSync();
      },
    );

    test(
      'startSync with a different attemptId while already running throws',
      () async {
        final apiClient = _FakeApiClient(
          (attemptId, answers, idempotencyKey) async => AnswerSubmitResponse(
            questionId: answers['question_id'] as String,
            acceptedAt: DateTime.utc(2026),
          ),
        );
        final engine = SyncEngine(
          outboxDao: dao,
          apiClient: apiClient,
          canary: canary,
        );

        engine.startSync('attempt-A');

        expect(() => engine.startSync('attempt-B'), throwsStateError);

        engine.stopSync();
      },
    );

    test(
      'the pending-answers read completes before any network call starts',
      () async {
        final events = <String>[];
        final recordingDao = _RecordingDao(db, events);
        await recordingDao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'q1',
          content: 'a',
        );
        await recordingDao.upsertAnswer(
          attemptId: 'attempt-1',
          questionId: 'q2',
          content: 'b',
        );

        final apiClient = _FakeApiClient((
          attemptId,
          answers,
          idempotencyKey,
        ) async {
          events.add('post_called:${answers['question_id']}');
          return AnswerSubmitResponse(
            questionId: answers['question_id'] as String,
            acceptedAt: DateTime.utc(2026),
          );
        });

        final engine = SyncEngine(
          outboxDao: recordingDao,
          apiClient: apiClient,
          canary: canary,
        );
        engine.startSync('attempt-1');

        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(events.first, 'query_complete');
        expect(events.skip(1), everyElement(startsWith('post_called:')));

        engine.stopSync();
      },
    );
  });
}
