import '../../../../core/network/models/exam_state.dart';

/// Thin seam between [ExamAttemptBloc] and the core network/storage
/// services — exists so the Bloc depends on one interface instead of
/// `ApiClient` + `AnswerOutboxDao` directly, and so tests can fake exactly
/// the three operations the Bloc needs without faking a whole `ApiClient`.
abstract class ExamAttemptRepository {
  Future<ExamState> startAttempt(String examId);

  /// Writes locally first (Phase 2 outbox) — never makes a network call
  /// itself; flushing is the sync engine's job (Phase 5).
  Future<void> saveAnswerLocally({
    required String attemptId,
    required String questionId,
    required String content,
  });

  Future<ExamState> finishAttempt(String attemptId);
}
