import 'dart:async';

import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/rate_limit_backoff.dart';

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
    RateLimitBackoff? backoff,
  })  : _outboxDao = outboxDao,
        _apiClient = apiClient,
        _canary = canary,
        _periodicInterval = periodicInterval,
        _createPeriodicTimer = createPeriodicTimer ?? Timer.periodic,
        _logger = logger ?? Logger(),
        _backoff = backoff ?? RateLimitBackoff();

  final AnswerOutboxDao _outboxDao;
  final ApiClient _apiClient;
  final NetworkCanary _canary;
  final Duration _periodicInterval;
  final PeriodicTimerFactory _createPeriodicTimer;
  final Logger _logger;
  final RateLimitBackoff _backoff;

  String? _runningAttemptId;
  String? _activeTaskId;
  StreamSubscription<void>? _canarySubscription;
  Timer? _periodicTimer;
  bool _isFlushing = false;

  final StreamController<void> _taskRejectedController = StreamController<void>.broadcast();

  /// Emits whenever a background flush discovers the currently-displayed
  /// task has already been closed out server-side
  /// (`NotCurrentTaskException`/`ResponseWindowExpiredException`) — the
  /// client's local view of "current task" is stale and must re-fetch
  /// `next-task`, the same idea as `TimerService.taskAdvancedExternally`
  /// for a different trigger (phase-07 Design Constraints).
  Stream<void> get taskRejectedExternally => _taskRejectedController.stream;

  /// Starts background outbox flushing for [attemptPublicId]. A no-op if
  /// already running for the *same* attempt. Throws [StateError] if called
  /// for a *different* attempt while already running — most likely a
  /// missing `stopSync()` after the previous attempt ended, so this fails
  /// loudly rather than silently running two attempts concurrently.
  ///
  /// Background flushing begins immediately — call [setActiveTask] before
  /// or in the same synchronous turn as `startSync` whenever the first
  /// task is already known, so no window exists where a background trigger
  /// could flush that task's row before it's marked active (QUAL-202,
  /// Phase 2 quality gate).
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

  /// Triggers an immediate flush pass for [attemptPublicId], independent
  /// of the canary/periodic triggers. Used by resume reconciliation
  /// (Phase 3) so outbox rows left over from a prior app session get an
  /// attempt right away instead of waiting up to `periodicInterval` for
  /// the first tick. A no-op if [attemptPublicId] isn't the currently
  /// running attempt.
  Future<void> flushNow(String attemptPublicId) {
    if (_runningAttemptId != attemptPublicId) return Future.value();
    return _flush(attemptPublicId);
  }

  /// Flushes exactly one row by id, bypassing the active-task exclusion.
  /// Used only by the flush-before-navigate hook (Phase 5/6) and
  /// force-submit (Phase 7) — an explicit action the student actually took,
  /// unlike a background tick.
  Future<void> flushOne(String pinnedItemPublicId) async {
    final attemptId = _runningAttemptId;
    if (attemptId == null) return;
    final row = await _outboxDao.getAnswer(attemptId, pinnedItemPublicId);
    if (row == null || row.status != AnswerSyncStatus.pending.name) return;
    await _flushOne(row);
  }

  Future<void> _flush(String attemptPublicId) async {
    if (_isFlushing || _backoff.isActive) return;
    _isFlushing = true;
    try {
      final pending = await _outboxDao.queryPendingByAttempt(attemptPublicId);
      final activeTaskId = _activeTaskId;
      var flushedAny = false;
      for (final answer in pending) {
        if (activeTaskId != null && answer.pinnedItemPublicId == activeTaskId) continue;
        await _flushOne(answer);
        flushedAny = true;
        // A 429 mid-pass must stop the rest of this pass immediately, not
        // just skip retrying the row that received it — the remaining
        // rows would otherwise fire more doomed requests into the same
        // rate-limit window and needlessly compound the backoff's
        // exponential growth within a single tick (phase-07 Design
        // Constraints).
        if (_backoff.isActive) break;
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
      _backoff.reset();
    } on NotCurrentTaskException catch (e) {
      // The server has already closed this task out from under the
      // client — the local "current task" view is stale, so the UI must
      // re-fetch next-task rather than sit on a task the server considers
      // done (phase-07 Design Constraints).
      await _outboxDao.markTerminalRejected(answer.attemptPublicId, answer.pinnedItemPublicId, e.message);
      _taskRejectedController.add(null);
    } on ResponseWindowExpiredException catch (e) {
      await _outboxDao.markTerminalRejected(answer.attemptPublicId, answer.pinnedItemPublicId, e.message);
      _taskRejectedController.add(null);
    } on ConflictException catch (e) {
      // Generic fallback — an already-submitted answer or any other/future
      // 409 cause not yet given its own type. Still terminal (Phase 2's
      // conservative baseline), but no task-refetch signal: unlike the two
      // typed causes above, this doesn't necessarily mean the client's
      // current-task view is stale.
      await _outboxDao.markTerminalRejected(answer.attemptPublicId, answer.pinnedItemPublicId, e.message);
    } on ValidationException catch (e) {
      // The server rejected this exact payload as malformed — retrying
      // the same bytes forever cannot succeed, unlike a network/server
      // blip (QUAL-201, Phase 2 quality gate). Not a 409, but
      // non-retryable for the same underlying reason.
      await _outboxDao.markTerminalRejected(answer.attemptPublicId, answer.pinnedItemPublicId, e.message);
    } on RateLimitException catch (e) {
      // A signal about the whole client's request rate, not this one row
      // — back off every flush attempt (not just this row) until the
      // cooldown elapses, rather than retrying the same burst on the very
      // next tick (phase-07 Design Constraints).
      _backoff.registerRateLimited(retryAfter: e.retryAfter);
      _logger.w('Answer flush rate-limited, backing off', error: e);
    } on ApiException catch (e) {
      // Transient (network/server) or session-level (AuthException) —
      // leave pending, retried on the next canary event or periodic tick.
      // AuthException is deliberately NOT marked terminal here: it signals
      // a broken session, not an invalid payload, so abandoning just this
      // one row wouldn't fix anything — it retries indefinitely until the
      // session recovers.
      _logger.w('Answer flush failed, left pending for next tick', error: e);
    }
  }

  /// Terminal teardown: closes the task-rejection stream. Not called
  /// between attempts — only at app/service teardown, mirroring
  /// `TimerService.dispose`.
  void dispose() {
    unawaited(_taskRejectedController.close());
  }
}
