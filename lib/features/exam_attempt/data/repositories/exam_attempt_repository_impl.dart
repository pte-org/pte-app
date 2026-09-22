import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/domain/attempt_preflight.dart';
import 'package:pte_app/features/exam_attempt/domain/client_capability_manifest.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

class ExamAttemptRepositoryImpl implements ExamAttemptRepository {
  ExamAttemptRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AttemptPreflight> preflight(String sessionPublicId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConfig.examAttemptsPath}/preflight',
      data: {
        'sessionPublicId': sessionPublicId,
        'capabilityManifest': ClientCapabilityManifest.fromRegistry().toJson(),
      },
    );
    return AttemptPreflight.fromJson(response.data!);
  }

  @override
  Future<AttemptTaskResponse> startOrResumeAttempt(
    String sessionPublicId, {
    bool deviceCheckConfirmed = false,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConfig.examAttemptsPath,
      data: {
        'sessionPublicId': sessionPublicId,
        // Required by the server's `StartAttemptRequest` (a primitive
        // `boolean`, not nullable — omitting it fails JSON deserialization
        // outright, HTTP 500, before any business logic runs). Always
        // The real pre-exam device-check flow supplies `true` after the
        // student confirms both microphone playback and test sound. The
        // initial request deliberately remains false so a session policy
        // requiring the check cannot be bypassed.
        'deviceCheckConfirmed': deviceCheckConfirmed,
        'capabilityManifest': ClientCapabilityManifest.fromRegistry().toJson(),
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
