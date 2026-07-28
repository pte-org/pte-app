import 'dart:async';

import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../storage/dao/answer_outbox_dao.dart';
import '../storage/drift_database.dart';
import 'network_canary.dart';

/// Orchestrates outbox flushing: ties storage (Phase 2), network (Phase 3),
/// and the network canary (Phase 4 timer-sync) together. Not a Bloc — a
/// shared service Phase 6's exam-delivery Bloc starts and stops.
class SyncEngine {
  SyncEngine({
    required AnswerOutboxDao outboxDao,
    required ApiClient apiClient,
    required NetworkCanary canary,
  }) : _outboxDao = outboxDao,
       _apiClient = apiClient,
       _canary = canary;

  final AnswerOutboxDao _outboxDao;
  final ApiClient _apiClient;
  final NetworkCanary _canary;

  String? _runningAttemptId;
  StreamSubscription<void>? _canarySubscription;

  /// Starts background outbox flushing for [attemptId]. Calling again with
  /// a *different* attemptId while already running is a bug — most likely
  /// a missing `stopSync()` after the previous exam was submitted — so
  /// this throws rather than silently running two attempts concurrently.
  void startSync(String attemptId) {
    final running = _runningAttemptId;
    if (running != null) {
      if (running == attemptId) return;
      throw StateError(
        'SyncEngine already running for attempt "$running"; '
        'call stopSync() before starting attempt "$attemptId".',
      );
    }
    _runningAttemptId = attemptId;
    _canarySubscription = _canary.available.listen((_) {
      unawaited(_flush(attemptId));
    });
  }

  void stopSync() {
    unawaited(_canarySubscription?.cancel());
    _canarySubscription = null;
    _runningAttemptId = null;
  }

  Future<void> _flush(String attemptId) async {
    final pending = await _outboxDao.queryPendingByAttemptId(attemptId);
    for (final answer in pending) {
      await _flushOne(answer);
    }
    if (pending.isNotEmpty) {
      await _outboxDao.checkpointWal();
    }
  }

  Future<void> _flushOne(AnswerOutbox answer) async {
    try {
      await _apiClient.submitAnswers(
        answer.attemptId,
        {'question_id': answer.questionId, 'content': answer.content},
        idempotencyKey: '${answer.attemptId}#${answer.questionId}',
      );
      await _outboxDao.markSynced(answer.attemptId, answer.questionId);
    } on ConflictException {
      await _outboxDao.markFailed(
        answer.attemptId,
        answer.questionId,
        'part closed',
      );
    } on ApiException {
      // Transient (network/server/401-after-refresh-failed) — leave
      // pending, retried automatically on the next canary "available" event.
    }
  }
}
