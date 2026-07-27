import 'dart:async';

import 'repositories/timer_repository.dart';
import 'task_view.dart';
import 'timer_phase.dart';
import 'timer_snapshot.dart';
import 'timer_state_response.dart';

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
  TimerService({required TimerRepository timerRepository, Stopwatch? stopwatch, TimerScheduler? scheduler})
    : _timerRepository = timerRepository,
      _stopwatch = stopwatch ?? Stopwatch(),
      _scheduler = scheduler ?? Timer.new;

  final TimerRepository _timerRepository;
  final Stopwatch _stopwatch;
  final TimerScheduler _scheduler;

  final StreamController<TimerSnapshot> _ticksController = StreamController<TimerSnapshot>.broadcast();
  final StreamController<void> _taskAdvancedController = StreamController<void>.broadcast();

  TimerPhase _phase = TimerPhase.prep;
  Duration _targetRemaining = Duration.zero;
  int _currentOrderIndex = 0;

  Timer? _pollTimer;
  Timer? _tickTimer;

  /// Emits on every server reconciliation and on the local sub-second UI
  /// tick between polls.
  Stream<TimerSnapshot> get ticks => _ticksController.stream;

  /// Emits whenever a poll reports a `currentOrderIndex` different from the
  /// last known value — distinct from [ticks] so a listener can tell
  /// "countdown updated" apart from "the current task itself changed"
  /// (e.g. a proctor-initiated advance).
  Stream<void> get taskAdvancedExternally => _taskAdvancedController.stream;

  TimerSnapshot get currentSnapshot {
    final remaining = _targetRemaining - _stopwatch.elapsed;
    return TimerSnapshot(
      phase: _phase,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      currentOrderIndex: _currentOrderIndex,
    );
  }

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
    _seed(deadline.difference(task.serverNow));
  }

  /// Resets the countdown to the server's authoritative state and adopts
  /// `response.phase` directly rather than re-deriving it.
  void reconcileFromServer(TimerStateResponse response) {
    final deadline = response.phase == TimerPhase.prep ? response.prepDeadline : response.responseDeadline;
    final orderIndexChanged = response.currentOrderIndex != _currentOrderIndex;

    _phase = response.phase;
    _currentOrderIndex = response.currentOrderIndex;
    _seed(deadline.difference(response.serverNow));

    if (orderIndexChanged) {
      _taskAdvancedController.add(null);
    }
  }

  void _seed(Duration remaining) {
    _targetRemaining = remaining.isNegative ? Duration.zero : remaining;
    _stopwatch
      ..reset()
      ..start();
    _ticksController.add(currentSnapshot);
  }

  /// Starts both the poll loop (`GET .../timer`, default every [interval])
  /// and a lightweight local sub-second tick loop for a smooth countdown
  /// display between polls — both driven by the same injectable
  /// [TimerScheduler], not two independent timer mechanisms (phase-04
  /// Design Constraints).
  void startPolling(String attemptPublicId, {Duration interval = _defaultPollInterval}) {
    _scheduleLocalTick();
    unawaited(_poll(attemptPublicId, interval));
  }

  void _scheduleLocalTick() {
    _tickTimer = _scheduler(_localTickInterval, () {
      _ticksController.add(currentSnapshot);
      _scheduleLocalTick();
    });
  }

  Future<void> _poll(String attemptPublicId, Duration interval) async {
    try {
      final response = await _timerRepository.fetchTimerState(attemptPublicId);
      reconcileFromServer(response);
    } catch (_) {
      // Silent retry — connectivity state is the Bloc's concern, not this
      // loop's; never block on a single failed poll (mirrors the Phase 0
      // reference `TimerService._poll`).
    }
    _pollTimer = _scheduler(interval, () {
      unawaited(_poll(attemptPublicId, interval));
    });
  }

  /// Cancels both timers without closing the streams — safe to call between
  /// attempts since this service is a long-lived singleton (mirrors
  /// `SyncEngine.stopSync`).
  void stop() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _pollTimer = null;
    _tickTimer = null;
  }

  /// Terminal teardown: stops both timers and closes both streams. Not
  /// called between attempts — only at app/service teardown.
  void dispose() {
    stop();
    unawaited(_ticksController.close());
    unawaited(_taskAdvancedController.close());
  }
}
