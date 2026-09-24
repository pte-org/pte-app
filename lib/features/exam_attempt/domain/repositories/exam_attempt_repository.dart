import 'package:pte_app/features/exam_attempt/domain/attempt_preflight.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Attempt lifecycle only (start/resume/advance/force-submit) — depends on
/// nothing beyond what an implementation needs to reach `ApiClient`. Never
/// import or depend on Phase 2's `AnswerOutboxDao`/`SyncEngine` here;
/// answer submission is a different concern with different retry/
/// persistence semantics. The one place those two concerns compose is the
/// resume-reconciliation step in `ExamAttemptBloc`, which reads the
/// outbox DAO itself rather than asking this repository to (phase-03
/// Design Constraints).
abstract class ExamAttemptRepository {
  Future<AttemptPreflight> preflight(String sessionPublicId);

  Future<AttemptTaskResponse> startOrResumeAttempt(
    String sessionPublicId, {
    bool deviceCheckConfirmed = false,
  });

  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId);

  /// Stubbed for shape-completeness now so Phase 7 (force-submit, FR-10)
  /// doesn't need to touch this repository — intentionally unwired to any
  /// `ExamAttemptBloc` event in this phase.
  Future<AttemptTaskResponse> forceSubmit(String attemptPublicId);
}
