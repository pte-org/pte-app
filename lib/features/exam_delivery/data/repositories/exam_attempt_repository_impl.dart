import '../../../../core/network/api_client.dart';
import '../../../../core/network/models/exam_state.dart';
import '../../../../core/storage/dao/answer_outbox_dao.dart';
import 'exam_attempt_repository.dart';

class ExamAttemptRepositoryImpl implements ExamAttemptRepository {
  ExamAttemptRepositoryImpl({
    required ApiClient apiClient,
    required AnswerOutboxDao outboxDao,
  }) : _apiClient = apiClient,
       _outboxDao = outboxDao;

  final ApiClient _apiClient;
  final AnswerOutboxDao _outboxDao;

  @override
  Future<ExamState> startAttempt(String examId) =>
      _apiClient.startAttempt(examId);

  @override
  Future<void> saveAnswerLocally({
    required String attemptId,
    required String questionId,
    required String content,
  }) {
    return _outboxDao.upsertAnswer(
      attemptId: attemptId,
      questionId: questionId,
      content: content,
    );
  }

  @override
  Future<ExamState> finishAttempt(String attemptId) =>
      _apiClient.finishAttempt(attemptId);
}
