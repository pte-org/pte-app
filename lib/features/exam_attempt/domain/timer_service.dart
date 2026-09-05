import 'dart:async';

import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/timer_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_state_response.dart';

/// Schedules a one-shot callback. Production uses [Timer.new]; tests inject
/// a fake that captures the [Duration] and lets the test manually invoke
/// the callback instead of waiting real time — same pattern
/// `ProactiveRefreshScheduler`'s `TimerFactory` uses for the auth-refresh
/// schedule (phase-04 Design Constraints).
typedef TimerScheduler = Timer Function(Duration duration, void Function() callback);

const Duration _defaultPollInterval = Duration(seconds: 10);
const Duration _localTickInterval = Duration(seconds: 1);

/// Anchors the exam countdown to the last server-reconciled deadline plus
/// elapsed monotonic [Stopwatch] ticks — never `DateTime.now()` (FR-09).
/// `phase` is self-derived only on the very first seed from a bare
/// [TaskView]; every later reconciliation adopts the server's own `phase`
/// field directly instead of re-deriving it (phase-04 Design Constraints).
class TimerService {
  TimerService({
    required TimerRepository timerRepository,
    Stopwatch? stopwatch,
    TimerScheduler? scheduler,
    Logger? logger,
  }) : _timerRepository = timerRepository,
       _stopwatch = stopwatch ?? Stopwatch(),
       _scheduler = scheduler ?? Timer.new,
       _logger = logger ?? Logger();

  final TimerRepository _timerRepository;
  final Stopwatch _stopwatch;
  final TimerScheduler _scheduler;
  final Logger _logger;

  /// Server-provided whole-attempt deadline (`TaskView.examEndTime`/
  /// `TimerStateResponse.examEndTime`) — fixed for the life of the attempt,
  /// so it's carried forward across every [_seed] call rather than re-read
  /// per task. Null only before the first seed/reconciliation, or for an
  /// attempt predating the backend field.
  DateTime? _examEndTime;

  final StreamController<TimerSnapshot> _ticksController = StreamController<TimerSnapshot>.broadcast();
  final StreamController<void> _taskAdvancedController = StreamController<void>.broadcast();

  TimerPhase _phase = TimerPhase.prep;
  Duration _targetRemaining = Duration.zero;
  Duration _examTargetRemaining = Duration.zero;
  int _currentOrderIndex = 0;

  Timer? _pollTimer;
  Timer? _tickTimer;
  Timer? _oneShotPollTimer;

  /// Set by [startPolling], cleared by [stop] — doubles as the "polling is
  /// currently active" flag [_scheduleOneShotPoll] checks, so a bare
  /// [seedFromTask]/[reconcileFromServer] call made before the first
  /// [startPolling] (or after [stop]) never schedules a stray one-shot poll
  /// with nothing to reconcile against (plans/phat-speaking-dynamic-prep-timing).
  String? _attemptPublicId;
  Duration _pollInterval = _defaultPollInterval;

  /// Bumped by [stop] (and therefore by [startPolling], which calls it
  /// first) so a poll/tick callback scheduled by a now-superseded
  /// `startPolling` call — including one already in-flight awaiting
  /// `fetchTimerState` when a new task transition starts polling again —
  /// recognizes it's stale and does nothing, rather than reconciling with
  /// an orphaned chain no `Timer.cancel()` could reach in time.
  int _generation = 0;

  /// Emits on every server reconciliation and on the local sub-second UI
  /// tick between polls.
  Stream<TimerSnapshot> get ticks => _ticksController.stream;

  /// Emits whenever a poll reports a `currentOrderIndex` different from the
  /// last known value — distinct from [ticks] so a listener can tell
  /// "countdown updated" apart from "the current task itself changed"
  /// (e.g. a proctor-initiated advance).
  Stream<void> get taskAdvancedExternally => _taskAdvancedController.stream;

  TimerSnapshot get currentSnapshot {
    return TimerSnapshot(
      phase: _phase,
      remaining: _nonNegative(_targetRemaining - _stopwatch.elapsed),
      currentOrderIndex: _currentOrderIndex,
      examRemaining: _nonNegative(_examTargetRemaining - _stopwatch.elapsed),
    );
  }

  static Duration _nonNegative(Duration duration) => duration.isNegative ? Duration.zero : duration;

  /// Bootstraps the countdown from a freshly-fetched [TaskView], before any
  /// timer poll has happened. Derives `phase` by comparing `serverNow`
  /// against `prepDeadline`/`responseDeadline`; a task already past both
  /// deadlines at fetch time seeds a zero/expired snapshot immediately
  /// rather than a negative countdown.
  void seedFromTask(TaskView task) {
    final DateTime deadline;
    if (task.serverNow.isBefore(task.prepDeadline)) {
      _phase = TimerPhase.prep;
      deadline = task.prepDeadline;
    } else {
      _phase = TimerPhase.response;
      deadline = task.responseDeadline;
    }
    _currentOrderIndex = task.orderIndex;
    _seed(deadline.difference(task.serverNow), serverNow: task.serverNow, examEndTime: task.examEndTime);
  }

  /// Resets the countdown to the server's authoritative state and adopts
  /// `response.phase` directly rather than re-deriving it.
  void reconcileFromServer(TimerStateResponse response) {
    final deadline = response.phase == TimerPhase.prep ? response.prepDeadline : response.responseDeadline;
    final orderIndexChanged = response.currentOrderIndex != _currentOrderIndex;

    _phase = response.phase;
    _currentOrderIndex = response.currentOrderIndex;
    _seed(deadline.difference(response.serverNow), serverNow: response.serverNow, examEndTime: response.examEndTime);
    // Re-arm the one-shot poll against the freshly reconciled deadline —
    // a no-op if polling isn't active (`_attemptPublicId` still null),
    // which is exactly the case every reconcileFromServer-only unit test
    // below exercises.
    _scheduleOneShotPoll(_generation);

    if (orderIndexChanged) {
      _taskAdvancedController.add(null);
    }
  }

  /// [examEndTime] is fixed for the whole attempt but re-supplied on every
  /// seed/reconciliation, so a null value here (an attempt predating the
  /// backend field) never overwrites an already-known one. [_examTargetRemaining]
  /// is recomputed against [serverNow] every call — same self-correcting
  /// pattern as [_targetRemaining] — rather than free-running off a single
  /// first-seed anchor.
  void _seed(Duration remaining, {required DateTime serverNow, DateTime? examEndTime}) {
    _targetRemaining = _nonNegative(remaining);
    _examEndTime ??= examEndTime;
    if (_examEndTime != null) {
      _examTargetRemaining = _nonNegative(_examEndTime!.difference(serverNow));
    }
    _stopwatch
      ..reset()
      ..start();
    _ticksController.add(currentSnapshot);
  }

  /// Starts both the poll loop (`GET .../timer`, default every [interval])
  /// and a lightweight local sub-second tick loop for a smooth countdown
  /// display between polls — both driven by the same injectable
  /// [TimerScheduler], not two independent timer mechanisms (phase-04
  /// Design Constraints). Calls [stop] first so calling this again on a
  /// later task transition (as `ExamAttemptBloc` does on every
  /// `NextTaskRequested`) can never leave a prior poll/tick chain running
  /// orphaned alongside the new one.
  void startPolling(String attemptPublicId, {Duration interval = _defaultPollInterval}) {
    stop();
    _attemptPublicId = attemptPublicId;
    _pollInterval = interval;
    final generation = _generation;
    _scheduleLocalTick(generation);
    _scheduleOneShotPoll(generation);
    unawaited(_poll(attemptPublicId, interval, generation));
  }

  void _scheduleLocalTick(int generation) {
    _tickTimer = _scheduler(_localTickInterval, () {
      if (generation != _generation) return;
      _ticksController.add(currentSnapshot);
      _scheduleLocalTick(generation);
    });
  }

  /// Schedules a one-shot poll timed to fire exactly when the local
  /// countdown ([currentSnapshot.remaining]) is expected to hit zero — so a
  /// short-prep task type's phase transition is reconciled promptly instead
  /// of waiting up to the full fixed [_pollInterval]
  /// (plans/phat-speaking-dynamic-prep-timing). Re-armed by every fresh
  /// reseed ([startPolling] and [reconcileFromServer]) so it always targets
  /// the current deadline, never a stale one. A no-op whenever polling
  /// isn't active ([_attemptPublicId] null) — [reconcileFromServer] calls
  /// this unconditionally, so this guard is what keeps direct
  /// reconcileFromServer-only unit tests (no [startPolling]) from
  /// scheduling a stray real [Timer].
  void _scheduleOneShotPoll(int generation) {
    _oneShotPollTimer?.cancel();
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null) return;
    _oneShotPollTimer = _scheduler(currentSnapshot.remaining, () {
      if (generation != _generation) return;
      // Cancel the still-pending periodic chain *before* reconciling, so
      // the reconciliation below's own tail-end rescheduling in [_poll] is
      // the only live periodic timer afterward — never two parallel
      // chains (plan-reviewer HIGH finding).
      _pollTimer?.cancel();
      _pollTimer = null;
      unawaited(_poll(attemptPublicId, _pollInterval, generation));
    });
  }

  Future<void> _poll(String attemptPublicId, Duration interval, int generation) async {
    try {
      final response = await _timerRepository.fetchTimerState(attemptPublicId);
      if (generation != _generation) return;
      reconcileFromServer(response);
    } on AttemptAlreadyCompleteException {
      // The attempt reached a terminal status through some path other than
      // this bloc's own completion flow — retrying forever can never
      // succeed once this specific, permanent cause is known, so stop the
      // whole poll/tick/one-shot chain outright instead of logging a
      // ConflictException every interval indefinitely
      // (plans/phat-speaking-dynamic-prep-timing follow-up). Guarded the
      // same way every other branch here is: a stale generation means a
      // newer poll/tick chain is already active, which stop() must never
      // cancel out from under.
      if (generation != _generation) return;
      stop();
      return;
    } catch (e, stackTrace) {
      // Silent retry — connectivity state is the Bloc's concern, not this
      // loop's; never block on a single failed poll (mirrors the Phase 0
      // reference `TimerService._poll`). Still logged, matching
      // `ProactiveRefreshScheduler`/`SyncEngine`'s equivalent retry loops,
      // so a failure is observable somewhere even though nothing here
      // surfaces it to the user.
      _logger.w('Timer poll failed, retrying in $interval', error: e, stackTrace: stackTrace);
    }
    if (generation != _generation) return;
    // Cancel any periodic timer already set before overwriting the field —
    // symmetric with _scheduleOneShotPoll's own cancel-before-overwrite
    // (plans/phat-speaking-dynamic-prep-timing Phase 4 code-review finding).
    // Without this, two _poll calls racing concurrently (e.g. the one-shot
    // firing and re-entering _poll while the *original* startPolling call's
    // _poll is still awaiting a slow fetchTimerState — plausible exactly
    // because the one-shot targets short prep windows) would have whichever
    // resolves last silently clobber the other's _pollTimer reference with
    // no cancellation, leaking the earlier one still armed and producing
    // two independently-firing periodic chains.
    _pollTimer?.cancel();
    _pollTimer = _scheduler(interval, () {
      if (generation != _generation) return;
      unawaited(_poll(attemptPublicId, interval, generation));
    });
  }

  /// Cancels both timers without closing the streams — safe to call between
  /// attempts since this service is a long-lived singleton (mirrors
  /// `SyncEngine.stopSync`). Bumps [_generation] so any callback already
  /// scheduled by the just-cancelled chain — including one in-flight
  /// awaiting [TimerRepository.fetchTimerState] — recognizes it's stale.
  void stop() {
    _generation++;
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _oneShotPollTimer?.cancel();
    _pollTimer = null;
    _tickTimer = null;
    _oneShotPollTimer = null;
    _attemptPublicId = null;
  }

  /// Terminal teardown: stops both timers and closes both streams. Not
  /// called between attempts — only at app/service teardown.
  void dispose() {
    stop();
    unawaited(_ticksController.close());
    unawaited(_taskAdvancedController.close());
  }
}
