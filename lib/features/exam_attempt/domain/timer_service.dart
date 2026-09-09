import 'dart:async';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';

/// Schedules a one-shot callback. Production uses [Timer.new]; tests inject
/// a fake that captures the [Duration] and lets the test manually invoke
/// the callback instead of waiting real time — same pattern
/// `ProactiveRefreshScheduler`'s `TimerFactory` convention.
typedef TimerScheduler = Timer Function(Duration duration, void Function() callback);

const Duration _localTickInterval = Duration(seconds: 1);

/// Client-side-exam-timer refactor (Phase 3): countdown and prep→response
/// phase transition run entirely on-device, anchored to wall-clock deadlines
/// computed once from [TaskView.prepSeconds]/[TaskView.responseSeconds] at
/// [seedFromTask] — never a server poll/reconciliation. Deliberately
/// `DateTime.now()`-anchored, not `Stopwatch`-anchored (the prior design's
/// FR-09 explicitly avoided `DateTime.now()` specifically to resist a
/// student changing their device clock — that anti-cheat concern no longer
/// applies now that server-side deadline enforcement itself is gone; see
/// `research/refactor_polling.md`). A wall-clock deadline also means
/// [currentSnapshot] is correct immediately after the app is backgrounded/
/// resumed for any length of time, with no special-case reconciliation
/// needed — recomputed fresh from `DateTime.now()` vs. the fixed deadline on
/// every read, unaffected by how long a [Timer] callback was delayed.
///
/// Known, accepted residual gap (code-reviewer LOW finding): a benign
/// wall-clock jump mid-task (OS NTP resync, a manual date/time change for a
/// reason unrelated to cheating) could still visibly skip/jump the countdown
/// or flip phase early/late — this is about robustness, not the adversarial
/// clock-tampering concern FR-09 addressed, and is judged acceptable given
/// the same tradeoff.
class TimerService {
  TimerService({TimerScheduler? scheduler}) : _scheduler = scheduler ?? Timer.new;

  final TimerScheduler _scheduler;

  final StreamController<TimerSnapshot> _ticksController = StreamController<TimerSnapshot>.broadcast();
  final StreamController<void> _taskAdvancedController = StreamController<void>.broadcast();

  TimerPhase _phase = TimerPhase.prep;
  DateTime? _prepDeadline;
  DateTime? _responseDeadline;

  /// Whole-attempt deadline (`TaskView.examEndTime`) — fixed for the life of
  /// the attempt, so it's carried forward across every [seedFromTask] call
  /// rather than re-read per task. Null only before the first seed, or for
  /// an attempt predating the backend field.
  DateTime? _examDeadline;

  int _currentOrderIndex = 0;

  Timer? _tickTimer;
  Timer? _phaseTransitionTimer;

  /// Bumped by [stop] (and therefore by [startPolling], which calls it
  /// first) so a tick/phase-transition callback scheduled by a
  /// now-superseded chain recognizes it's stale and does nothing.
  int _generation = 0;

  /// Emits on every local sub-second UI tick and on every phase transition.
  Stream<TimerSnapshot> get ticks => _ticksController.stream;

  /// Never emits (client-side-exam-timer Phase 3) — proctor-initiated
  /// external task advances had no detection signal once server polling was
  /// removed (plan Risk, accepted capability loss, no replacement chosen).
  /// Kept only so downstream consumers ([ExamAttemptBloc]) need no interface
  /// change; safe to subscribe to, it simply never fires.
  Stream<void> get taskAdvancedExternally => _taskAdvancedController.stream;

  TimerSnapshot get currentSnapshot {
    final now = DateTime.now();
    final deadline = _phase == TimerPhase.prep ? _prepDeadline : _responseDeadline;
    final examDeadline = _examDeadline;
    return TimerSnapshot(
      phase: _phase,
      remaining: deadline == null ? Duration.zero : _nonNegative(deadline.difference(now)),
      currentOrderIndex: _currentOrderIndex,
      examRemaining: examDeadline == null ? Duration.zero : _nonNegative(examDeadline.difference(now)),
    );
  }

  static Duration _nonNegative(Duration duration) => duration.isNegative ? Duration.zero : duration;

  /// Bootstraps the countdown from a freshly-fetched [TaskView] — computes
  /// local wall-clock deadlines from [TaskView.prepSeconds]/[TaskView.responseSeconds]
  /// anchored to `DateTime.now()` at this exact call, per FR-01. A zero-prep
  /// task (`prepSeconds == 0`) starts directly in [TimerPhase.response],
  /// matching the server's own equivalent collapse-immediately behavior.
  /// Does not itself (re)start the tick/phase-transition timer chain — the
  /// caller ([ExamAttemptBloc]) calls [startPolling] right after, exactly as
  /// it always has.
  void seedFromTask(TaskView task) {
    final now = DateTime.now();
    _currentOrderIndex = task.orderIndex;
    _phase = task.prepSeconds > 0 ? TimerPhase.prep : TimerPhase.response;
    _prepDeadline = now.add(Duration(seconds: task.prepSeconds));
    _responseDeadline = now.add(Duration(seconds: task.prepSeconds + task.responseSeconds));
    _examDeadline ??= task.examEndTime;
    _ticksController.add(currentSnapshot);
  }

  /// (Re)arms the local tick + phase-transition timer chain against whatever
  /// deadlines [seedFromTask] most recently established. `attemptPublicId`
  /// is accepted but unused — kept only for interface compatibility with
  /// [ExamAttemptBloc]'s existing call sites (no more network poll to target
  /// it at). Retained method name for the same reason, despite no longer
  /// polling anything (candidate for a rename in the Phase 7 cleanup pass).
  ///
  /// Calls [stop] first, so calling this again on a later task transition —
  /// or from `AppResumed`, with NO preceding [seedFromTask] call — can never
  /// leave a prior chain running orphaned alongside a new one. The
  /// `AppResumed` case is exactly why this is safe without a `Stopwatch` to
  /// reconcile: [currentSnapshot] and [_schedulePhaseTransition] both
  /// recompute fresh from `DateTime.now()` against the fixed deadlines
  /// [seedFromTask] set, so however long the app was backgrounded, the very
  /// next read/callback is already correct — no drift to correct for.
  void startPolling(String attemptPublicId) {
    stop();
    final generation = _generation;
    _scheduleTick(generation);
    _schedulePhaseTransition(generation);
  }

  void _scheduleTick(int generation) {
    _tickTimer = _scheduler(_localTickInterval, () {
      if (generation != _generation) return;
      _ticksController.add(currentSnapshot);
      _scheduleTick(generation);
    });
  }

  /// One-shot, timed to fire exactly when [_prepDeadline] is reached, so a
  /// short-prep task's phase transition happens at the correct instant
  /// instead of waiting up to a full second for the next tick. A no-op if
  /// already in [TimerPhase.response] (zero-prep task, or re-armed after the
  /// transition already happened) — nothing left to transition to.
  void _schedulePhaseTransition(int generation) {
    _phaseTransitionTimer?.cancel();
    if (_phase == TimerPhase.response) return;
    final deadline = _prepDeadline;
    if (deadline == null) return;
    _phaseTransitionTimer = _scheduler(_nonNegative(deadline.difference(DateTime.now())), () {
      if (generation != _generation) return;
      _phase = TimerPhase.response;
      _ticksController.add(currentSnapshot);
    });
  }

  /// Cancels both timers without closing the streams — safe to call between
  /// attempts since this service is a long-lived singleton. Bumps
  /// [_generation] so any callback already scheduled by the just-cancelled
  /// chain recognizes it's stale.
  void stop() {
    _generation++;
    _tickTimer?.cancel();
    _phaseTransitionTimer?.cancel();
    _tickTimer = null;
    _phaseTransitionTimer = null;
  }

  /// Terminal teardown: stops both timers and closes both streams. Not
  /// called between attempts — only at app/service teardown.
  void dispose() {
    stop();
    unawaited(_ticksController.close());
    unawaited(_taskAdvancedController.close());
  }
}
