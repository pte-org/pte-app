import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aptis_app/core/network/api_client.dart';
import 'package:aptis_app/core/network/api_exceptions.dart';
import 'package:aptis_app/core/network/models/exam_state.dart';
import 'package:aptis_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:aptis_app/core/storage/drift_database.dart';
import 'package:aptis_app/core/sync/network_canary.dart';
import 'package:aptis_app/core/sync/sync_engine.dart';
import 'package:aptis_app/features/exam_delivery/data/repositories/exam_attempt_repository.dart';
import 'package:aptis_app/features/exam_delivery/domain/entities/exam_attempt_state.dart';
import 'package:aptis_app/features/exam_delivery/presentation/bloc/exam_attempt_bloc.dart';
import 'package:aptis_app/features/exam_delivery/presentation/bloc/exam_attempt_event.dart';

/// Hand-written fake — records call order across all three repository
/// operations in one list, so tests can assert ordering (write-before-network,
/// finish-before-stopSync) without a mocking package.
class _FakeExamAttemptRepository implements ExamAttemptRepository {
  _FakeExamAttemptRepository({
    Future<ExamState> Function(String examId)? startAttemptHandler,
    Future<ExamState> Function(String attemptId)? finishAttemptHandler,
    List<String>? callLog,
  }) : _startAttemptHandler = startAttemptHandler,
       _finishAttemptHandler = finishAttemptHandler,
       callLog = callLog ?? [];

  final Future<ExamState> Function(String examId)? _startAttemptHandler;
  final Future<ExamState> Function(String attemptId)? _finishAttemptHandler;
  final List<String> callLog;
  final List<Map<String, String>> savedAnswers = [];

  @override
  Future<ExamState> startAttempt(String examId) {
    callLog.add('startAttempt');
    return _startAttemptHandler!(examId);
  }

  @override
  Future<void> saveAnswerLocally({
    required String attemptId,
    required String questionId,
    required String content,
  }) async {
    callLog.add('saveAnswerLocally');
    savedAnswers.add({
      'attemptId': attemptId,
      'questionId': questionId,
      'content': content,
    });
  }

  @override
  Future<ExamState> finishAttempt(String attemptId) {
    callLog.add('finishAttempt');
    return _finishAttemptHandler!(attemptId);
  }
}

/// Hand-written fake `SyncEngine` — overrides only [startSync]/[stopSync] to
/// record calls (into a shared [callLog] when provided), bypassing the real
/// outbox-flush machinery entirely since the Bloc only ever calls these two
/// methods on it.
class _RecordingSyncEngine extends SyncEngine {
  _RecordingSyncEngine({
    required super.outboxDao,
    required super.apiClient,
    required super.canary,
    List<String>? callLog,
  }) : callLog = callLog ?? [];

  final List<String> callLog;
  final List<String> startedAttemptIds = [];
  int stopCallCount = 0;

  @override
  void startSync(String attemptId) {
    startedAttemptIds.add(attemptId);
    callLog.add('startSync');
  }

  @override
  void stopSync() {
    stopCallCount++;
    callLog.add('stopSync');
  }
}

class _DummyApiClient extends ApiClient {
  _DummyApiClient() : super(Dio());
}

void main() {
  group('ExamAttemptBloc', () {
    late AppDatabase db;
    late AnswerOutboxDao dao;
    late NetworkCanary canary;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = AnswerOutboxDao(db);
      canary = NetworkCanary(availableStream: const Stream<void>.empty());
    });

    tearDown(() async {
      await db.close();
    });

    _RecordingSyncEngine buildSyncEngine({List<String>? callLog}) {
      return _RecordingSyncEngine(
        outboxDao: dao,
        apiClient: _DummyApiClient(),
        canary: canary,
        callLog: callLog,
      );
    }

    test(
      'StartExamAttemptEvent emits InProgress populated from the API response, and starts the sync engine exactly once',
      () async {
        final repository = _FakeExamAttemptRepository(
          startAttemptHandler: (examId) async => ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: const Duration(seconds: 1800),
          ),
        );
        final syncEngine = buildSyncEngine();
        final bloc = ExamAttemptBloc(
          repository: repository,
          syncEngine: syncEngine,
        );

        final states = <ExamAttemptState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const StartExamAttemptEvent('exam-1'));
        await Future<void>.delayed(Duration.zero);

        expect(states.length, 1);
        final inProgress = states.single as ExamAttemptInProgress;
        expect(inProgress.attemptId, 'attempt-1');
        expect(inProgress.currentPartId, 'part-1');
        expect(inProgress.timeRemaining, const Duration(seconds: 1800));
        expect(syncEngine.startedAttemptIds, ['attempt-1']);

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'AnswerQuestionEvent writes to the outbox DAO before anything else, and increments pendingAnswerCount',
      () async {
        final repository = _FakeExamAttemptRepository(
          startAttemptHandler: (examId) async => const ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: Duration(seconds: 1800),
          ),
        );
        final syncEngine = buildSyncEngine();
        final bloc = ExamAttemptBloc(
          repository: repository,
          syncEngine: syncEngine,
        );

        bloc.add(const StartExamAttemptEvent('exam-1'));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const AnswerQuestionEvent(questionId: 'q1', content: 'B'));
        await Future<void>.delayed(Duration.zero);

        expect(repository.callLog, ['startAttempt', 'saveAnswerLocally']);
        expect(repository.savedAnswers.single, {
          'attemptId': 'attempt-1',
          'questionId': 'q1',
          'content': 'B',
        });

        final state = bloc.state as ExamAttemptInProgress;
        expect(state.pendingAnswerCount, 1);
        expect(state.questionsAnswered, 1);

        await bloc.close();
      },
    );

    test(
      'TimerTickEvent updates only timeRemaining, no other field mutated',
      () async {
        final repository = _FakeExamAttemptRepository(
          startAttemptHandler: (examId) async => const ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: Duration(seconds: 1800),
          ),
        );
        final syncEngine = buildSyncEngine();
        final bloc = ExamAttemptBloc(
          repository: repository,
          syncEngine: syncEngine,
        );

        bloc.add(const StartExamAttemptEvent('exam-1'));
        await Future<void>.delayed(Duration.zero);

        final before = bloc.state as ExamAttemptInProgress;

        bloc.add(const TimerTickEvent(900));
        await Future<void>.delayed(Duration.zero);

        final after = bloc.state as ExamAttemptInProgress;
        expect(after.timeRemaining, const Duration(seconds: 900));
        expect(after.attemptId, before.attemptId);
        expect(after.currentPartId, before.currentPartId);
        expect(after.questionsAnswered, before.questionsAnswered);
        expect(after.pendingAnswerCount, before.pendingAnswerCount);
        expect(after.failedAnswerCount, before.failedAnswerCount);

        await bloc.close();
      },
    );

    test(
      'SubmitExamEvent: a 409 from the API yields ExamAttemptError, not Submitted',
      () async {
        final repository = _FakeExamAttemptRepository(
          startAttemptHandler: (examId) async => const ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: Duration(seconds: 1800),
          ),
          finishAttemptHandler: (attemptId) async =>
              throw const ConflictException(),
        );
        final syncEngine = buildSyncEngine();
        final bloc = ExamAttemptBloc(
          repository: repository,
          syncEngine: syncEngine,
        );

        bloc.add(const StartExamAttemptEvent('exam-1'));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const SubmitExamEvent());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state, isA<ExamAttemptError>());
        expect(syncEngine.stopCallCount, 0);

        await bloc.close();
      },
    );

    test(
      'SubmitExamEvent: on success, stopSync() is called before ExamAttemptSubmitted is emitted',
      () async {
        final callLog = <String>[];
        final repository = _FakeExamAttemptRepository(
          startAttemptHandler: (examId) async => const ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: Duration(seconds: 1800),
          ),
          finishAttemptHandler: (attemptId) async => const ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: Duration.zero,
          ),
          callLog: callLog,
        );
        final syncEngine = buildSyncEngine(callLog: callLog);
        final bloc = ExamAttemptBloc(
          repository: repository,
          syncEngine: syncEngine,
        );

        bloc.add(const StartExamAttemptEvent('exam-1'));
        await Future<void>.delayed(Duration.zero);
        callLog.clear();

        final states = <ExamAttemptState>[];
        final sub = bloc.stream.listen((state) {
          states.add(state);
          callLog.add('state:${state.runtimeType}');
        });

        bloc.add(const SubmitExamEvent());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state, isA<ExamAttemptSubmitted>());
        expect(callLog, [
          'finishAttempt',
          'stopSync',
          'state:ExamAttemptSubmitted',
        ]);

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'going offline then answering still writes the answer and never emits an error',
      () async {
        final repository = _FakeExamAttemptRepository(
          startAttemptHandler: (examId) async => const ExamState(
            attemptId: 'attempt-1',
            currentPartId: 'part-1',
            timeRemaining: Duration(seconds: 1800),
          ),
        );
        final syncEngine = buildSyncEngine();
        final bloc = ExamAttemptBloc(
          repository: repository,
          syncEngine: syncEngine,
        );

        bloc.add(const StartExamAttemptEvent('exam-1'));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const ConnectivityChangedEvent(isOnline: false));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<ExamAttemptOffline>());

        bloc.add(const AnswerQuestionEvent(questionId: 'q1', content: 'B'));
        await Future<void>.delayed(Duration.zero);

        expect(repository.savedAnswers.single['questionId'], 'q1');
        expect(bloc.state, isNot(isA<ExamAttemptError>()));
        final offline = bloc.state as ExamAttemptOffline;
        expect(offline.pendingAnswerCount, 1);

        await bloc.close();
      },
    );
  });
}
