import 'dart:async';

import 'package:logger/logger.dart';

import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../network/network_canary.dart';
import '../storage/answer_sync_status.dart';
import '../storage/app_database.dart';
import '../storage/dao/answer_outbox_dao.dart';

/// Matches [Timer.periodic]'s signature so a fake factory can be injected
/// for deterministic tests (no real wall-clock waits).
typedef PeriodicTimerFactory = Timer Function(Duration period, void Function(Timer timer) callback);

/// Orchestrates outbox flushing: ties storage ([AnswerOutboxDao]), network
/// ([ApiClient]), and the connectivity canary ([NetworkCanary]) together.
/// Not a `Bloc` — a plain Dart service the exam-delivery `Bloc` starts and
/// stops (Phase 3 onward); must not import `flutter_bloc` types.
///
/// The single most important behavioral constraint here: a background
/// flush (canary or periodic tick) must never flush the row for the task
/// currently displayed to the student — see [setActiveTask] — because a
/// successful submit advances the attempt's current-task pointer on the
/// server. Only an explicit [flushOne] call (navigate-away / force-submit)
/// flushes the active row (phase-02 Design Constraints).
class SyncEngine {
  SyncEngine({
    required AnswerOutboxDao outboxDao,
    required ApiClient apiClient,
    required NetworkCanary canary,
    Duration periodicInterval = const Duration(seconds: 30),
    PeriodicTimerFactory? createPeriodicTimer,
    Logger? logger,
  })  : _outboxDao = outboxDao,
        _apiClient = apiClient,
        _canary = canary,
        _periodicInterval = periodicInterval,
        _createPeriodicTimer = createPeriodicTimer ?? Timer.periodic,
        _logger = logger ?? Logger();

  final AnswerOutboxDao _outboxDao;
  final ApiClient _apiClient;
  final NetworkCanary _canary;
  final Duration _periodicInterval;
  final PeriodicTimerFactory _createPeriodicTimer;
  final Logger _logger;

  String? _runningAttemptId;
  String? _activeTaskId;
  StreamSubscription<void>? _canarySubscription;
  Timer? _periodicTimer;
  bool _isFlushing = false;

  /// Starts background outbox flushing for [attemptPublicId]. A no-op if
  /// already running for the *same* attempt. Throws [StateError] if called
  /// for a *different* attempt while already running — most likely a
  /// missing `stopSync()` after the previous attempt ended, so this fails
  /// loudly rather than silently running two attempts concurrently.
  void startSync(String attemptPublicId) {
    final running = _runningAttemptId;
    if (running != null) {
      if (running == attemptPublicId) return;
      throw StateError(
        'SyncEngine already running for attempt "$running"; '
        'call stopSync() before starting attempt "$attemptPublicId".',
      );
    }
    _runningAttemptId = attemptPublicId;
    _canarySubscription = _canary.available.listen((_) => unawaited(_flush(attemptPublicId)));
    _periodicTimer = _createPeriodicTimer(_periodicInterval, (_) => unawaited(_flush(attemptPublicId)));
  }

  void stopSync() {
    unawaited(_canarySubscription?.cancel());
    _canarySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _runningAttemptId = null;
    _activeTaskId = null;
  }

  /// Records the task currently displayed to the student, excluded from
  /// background (canary/periodic) flush passes. Pass `null` when no task
  /// is displayed (e.g. between tasks).
  void setActiveTask(String? pinnedItemPublicId) {
    _activeTaskId = pinnedItemPublicId;
  }

  /// Flushes exactly one row by id, bypassing the active-task exclusion.
  /// Used only by the flush-before-navigate hook (Phase 5/6) and
  /// force-submit (Phase 7) — an explicit action the student actually took,
  /// unlike a background tick.
  Future<void> flushOne(String pinnedItemPublicId) async {
    final attemptId = _runningAttemptId;
    if (attemptId == null) return;
    final rows = await _outboxDao.queryByAttempt(attemptId);
    for (final row in rows) {
      if (row.pinnedItemPublicId == pinnedItemPublicId && row.status == AnswerSyncStatus.pending.name) {
        await _flushOne(row);
        return;
      }
    }
  }

  Future<void> _flush(String attemptPublicId) async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final pending = await _outboxDao.queryPendingByAttempt(attemptPublicId);
      final activeTaskId = _activeTaskId;
      var flushedAny = false;
      for (final answer in pending) {
        if (activeTaskId != null && answer.pinnedItemPublicId == activeTaskId) continue;
        await _flushOne(answer);
        flushedAny = true;
      }
      if (flushedAny) {
        await _outboxDao.checkpointWal();
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _flushOne(AnswerOutbox answer) async {
    try {
      await _apiClient.submitAnswer(
        attemptPublicId: answer.attemptPublicId,
        pinnedItemPublicId: answer.pinnedItemPublicId,
        payload: answer.payload,
      );
      await _outboxDao.markSynced(answer.attemptPublicId, answer.pinnedItemPublicId);
    } on ConflictException catch (e) {
      await _outboxDao.markTerminalRejected(answer.attemptPublicId, answer.pinnedItemPublicId, e.message);
    } on ApiException catch (e) {
      // Transient (network/server) — leave pending, retried automatically
      // on the next canary event or periodic tick.
      _logger.w('Answer flush failed, left pending for next tick', error: e);
    }
  }
}
