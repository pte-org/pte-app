import '../../../../core/network/api_client.dart';
import '../../domain/repositories/exam_attempt_repository.dart';
import '../../domain/task_view.dart';

class ExamAttemptRepositoryImpl implements ExamAttemptRepository {
  ExamAttemptRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AttemptTaskResponse> startOrResumeAttempt(String sessionPublicId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/exam-delivery/attempts',
      data: {'sessionPublicId': sessionPublicId},
    );
    return AttemptTaskResponse.fromJson(response.data!);
  }

  @override
  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/exam-delivery/attempts/$attemptPublicId/next-task',
    );
    return AttemptTaskResponse.fromJson(response.data!);
  }

  @override
  Future<void> forceSubmit(String attemptPublicId) {
    return _apiClient.post<void>('/api/exam-delivery/attempts/$attemptPublicId/submit');
  }
}
