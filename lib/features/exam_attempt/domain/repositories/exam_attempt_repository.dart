import 'package:pte_app/features/exam_attempt/domain/attempt_preflight.dart';
import 'package:pte_app/features/exam_attempt/domain/task_navigation_direction.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Attempt lifecycle only (start/resume/advance/force-submit) — depends on
/// nothing beyond what an implementation needs to reach `ApiClient`. Never
/// import or depend on `AnswerOutboxDao`/`SyncEngine` here; answer submission
/// preparation is a different concern with different retry/persistence
/// semantics. The two concerns compose in `ExamAttemptBloc`, which owns the
/// terminal preparation sequence and resume reconciliation.
abstract class ExamAttemptRepository {
  Future<AttemptPreflight> preflight(String sessionPublicId);

  Future<AttemptTaskResponse> startOrResumeAttempt(
    String sessionPublicId, {
    bool deviceCheckConfirmed = false,
  });

  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId);

  /// Bulk-prefetch all tasks for the attempt in order. Used on exam
  /// start/resume so the client can navigate locally without round-trips.
  Future<List<AttemptTaskResponse>> fetchAllTasks(String attemptPublicId);

  Future<AttemptTaskResponse> navigateTask({
    required String attemptPublicId,
    required String fromPinnedItemPublicId,
    required TaskNavigationDirection direction,
  });

  /// Requests the server's idempotent terminal submission operation. The
  /// caller must complete answer/media preparation before invoking it.
  Future<AttemptTaskResponse> forceSubmit(String attemptPublicId);
}
