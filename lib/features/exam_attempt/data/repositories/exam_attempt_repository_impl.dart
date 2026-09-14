import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

class ExamAttemptRepositoryImpl implements ExamAttemptRepository {
  ExamAttemptRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AttemptTaskResponse> startOrResumeAttempt(
    String sessionPublicId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConfig.examAttemptsPath,
      data: {
        'sessionPublicId': sessionPublicId,
        // Required by the server's `StartAttemptRequest` (a primitive
        // `boolean`, not nullable — omitting it fails JSON deserialization
        // outright, HTTP 500, before any business logic runs). Always
        // `false` for now: the standalone "Test Mic and Sound" dev-preview
        // screen (features/device_check) is not wired into this real
        // pre-exam flow yet (explicit, separate product decision — see
        // plans/phat-device-check-test-mic-and-sound-ui), so there is no
        // real device-check result to report here. `false` is honest per
        // the server field's own doc comment ("absent/false always means
        // not confirmed") and only blocks attempt start when a session's
        // policy specifically requires device check, which none currently
        // do. Revisit once/if device check is wired into this flow for real
        // (plans/phat-speaking-api-e2e-verify Phase 3 finding).
        'deviceCheckConfirmed': false,
      },
    );
    return AttemptTaskResponse.fromJson(response.data!);
  }

  @override
  Future<AttemptTaskResponse> fetchNextTask(String attemptPublicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConfig.examAttemptsPath}/$attemptPublicId/next-task',
    );
    return AttemptTaskResponse.fromJson(response.data!);
  }

  @override
  Future<void> forceSubmit(String attemptPublicId) {
    return _apiClient.post<void>(
      '${AppConfig.examAttemptsPath}/$attemptPublicId/submit',
    );
  }
}
