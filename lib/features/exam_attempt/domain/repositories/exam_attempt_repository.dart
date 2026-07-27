import '../task_view.dart';

/// Attempt lifecycle only (start/resume/advance/force-submit) — depends on
/// nothing beyond what an implementation needs to reach `ApiClient`. Never
/// import or depend on Phase 2's `AnswerOutboxDao`/`SyncEngine` here;
/// answer submission is a different concern with different retry/
/// persistence semantics. The one place those two concerns compose is the
/// resume-reconciliation step in `ExamAttemptBloc`, which reads the
/// outbox DAO itself rather than asking this repository to (phase-03
/// Design Constraints).
abstract class ExamAttemptRepository {
  Future<AttemptTaskResponse> startOrResumeAttempt(String sessionPublicId);

  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId);

  /// Stubbed for shape-completeness now so Phase 7 (force-submit, FR-10)
  /// doesn't need to touch this repository — intentionally unwired to any
  /// `ExamAttemptBloc` event in this phase.
  Future<void> forceSubmit(String attemptPublicId);
}
