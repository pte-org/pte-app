/// `kDebugMode`-gated dev-preview-only fakes so `ReadingTaskPreviewScreen`
/// can drive a real `ExamAttemptBloc` into `AttemptInProgress` for a single
/// hand-picked fixture `TaskView`, without touching a real backend. Never
/// registered in `exam_attempt_module.dart` — constructed directly by the
/// dev preview screen alongside its own throwaway `ExamAttemptBloc`/
/// `TimerService` instances, entirely separate from the app's real
/// `getIt`-registered singletons.
library;

import '../domain/repositories/exam_attempt_repository.dart';
import '../domain/repositories/session_entry_repository.dart';
import '../domain/repositories/timer_repository.dart';
import '../domain/task_view.dart';
import '../domain/timer_state_response.dart';

/// Resolves any input to a fixed dev session ID — there is no real session
/// to resolve.
class DevSessionEntryRepository implements SessionEntryRepository {
  const DevSessionEntryRepository();

  @override
  Future<String> resolveSessionPublicId(String rawInput) async => 'dev-session';
}

/// Serves exactly one caller-set [nextTask] on `startOrResumeAttempt`, then
/// completes the attempt on the following `fetchNextTask` — mirrors the
/// preview screen's own UX (pick one fixture, see it rendered, tap "Next"
/// to finish and go back to picking another).
class DevExamAttemptRepository implements ExamAttemptRepository {
  DevExamAttemptRepository({required this.nextTask});

  /// Set by the preview screen immediately before dispatching
  /// `SessionResolutionRequested` for a freshly-tapped fixture.
  TaskView nextTask;

  @override
  Future<AttemptTaskResponse> startOrResumeAttempt(String sessionPublicId) async {
    return AttemptTaskResponse(attemptPublicId: 'dev-attempt', attemptStatus: 'IN_PROGRESS', completed: false, task: nextTask);
  }

  @override
  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId) async {
    return const AttemptTaskResponse(attemptPublicId: 'dev-attempt', attemptStatus: 'COMPLETED', completed: true);
  }

  @override
  Future<void> forceSubmit(String attemptPublicId) async {}
}

/// Always fails — `TimerService._poll` already catches and silently retries
/// any `fetchTimerState` error, so the dev preview's countdown still works
/// correctly end-to-end from `TimerService`'s own local `Stopwatch` tick
/// loop (seeded once from the fixture's own `prepDeadline`/
/// `responseDeadline`), without needing a working fake reconciliation
/// response.
class DevTimerRepository implements TimerRepository {
  const DevTimerRepository();

  @override
  Future<TimerStateResponse> fetchTimerState(String attemptPublicId) {
    throw UnimplementedError('Dev preview has no backend — TimerService retries silently, this is expected.');
  }
}
