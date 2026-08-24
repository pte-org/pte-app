/// `kDebugMode`-gated dev-preview-only fakes so `ReadingTaskPreviewScreen`
/// can drive a real `ExamAttemptBloc` into `AttemptInProgress` for a single
/// hand-picked fixture `TaskView`, without touching a real backend. Never
/// registered in `exam_attempt_module.dart` — constructed directly by the
/// dev preview screen alongside its own throwaway `ExamAttemptBloc`/
/// `TimerService` instances, entirely separate from the app's real
/// `getIt`-registered singletons.
library;

import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/timer_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_state_response.dart';

/// Resolves any input to a fixed dev session ID — there is no real session
/// to resolve.
class DevSessionEntryRepository implements SessionEntryRepository {
  const DevSessionEntryRepository();

  @override
  Future<String> resolveSessionPublicId(String rawInput) async => 'dev-session';
}

/// Shared anchor between [DevExamAttemptRepository] and [DevTimerRepository]
/// so a poll can answer with the *real* current phase, computed from actual
/// elapsed wall-clock time since the fixture was selected.
///
/// `TimerService.seedFromTask` only derives `phase` once, at the very first
/// seed — every later transition (including prep → response) is adopted
/// only from a successful `reconcileFromServer` call (`TimerService`'s own
/// doc comment: "phase is self-derived only on the very first seed...every
/// later reconciliation adopts the server's own phase field directly").
/// A dev timer repository that never answers successfully would leave the
/// countdown display ticking correctly (that's driven by a local
/// `Stopwatch`, independent of polling) while the phase itself stays stuck
/// at `prep` forever — recording would never auto-start. This class exists
/// so [DevTimerRepository] can give a real, correctly-transitioning answer
/// instead.
class DevAttemptClock {
  DevAttemptClock(this.task) : startedAt = DateTime.now();

  TaskView task;
  DateTime startedAt;

  void restart(TaskView newTask) {
    task = newTask;
    startedAt = DateTime.now();
  }

  TimerStateResponse currentTimerState(String attemptPublicId) {
    final now = DateTime.now();
    final prepDeadline = startedAt.add(Duration(seconds: task.prepSeconds));
    final responseDeadline = prepDeadline.add(Duration(seconds: task.responseSeconds));
    return TimerStateResponse(
      phase: now.isBefore(prepDeadline) ? TimerPhase.prep : TimerPhase.response,
      currentOrderIndex: task.orderIndex,
      prepDeadline: prepDeadline,
      responseDeadline: responseDeadline,
      serverNow: now,
    );
  }
}

/// Serves [DevAttemptClock.task] on `startOrResumeAttempt` (restarting the
/// clock so its elapsed-time math starts fresh for this selection), then
/// completes the attempt on the following `fetchNextTask` — mirrors the
/// preview screen's own UX (pick one fixture, see it rendered, tap "Next"
/// to finish and go back to picking another).
class DevExamAttemptRepository implements ExamAttemptRepository {
  DevExamAttemptRepository({required this.clock});

  final DevAttemptClock clock;

  @override
  Future<AttemptTaskResponse> startOrResumeAttempt(String sessionPublicId) async {
    clock.restart(clock.task);
    return AttemptTaskResponse(attemptPublicId: 'dev-attempt', attemptStatus: 'IN_PROGRESS', completed: false, task: clock.task);
  }

  @override
  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId) async {
    return const AttemptTaskResponse(attemptPublicId: 'dev-attempt', attemptStatus: 'COMPLETED', completed: true);
  }

  @override
  Future<void> forceSubmit(String attemptPublicId) async {}
}

/// Answers every poll with [DevAttemptClock.currentTimerState] — a real,
/// correctly-transitioning response computed from actual elapsed time, not
/// a canned/failing stub. See [DevAttemptClock]'s doc for why a
/// never-succeeding fake would silently break the whole preview.
class DevTimerRepository implements TimerRepository {
  const DevTimerRepository(this.clock);

  final DevAttemptClock clock;

  @override
  Future<TimerStateResponse> fetchTimerState(String attemptPublicId) async => clock.currentTimerState(attemptPublicId);
}
