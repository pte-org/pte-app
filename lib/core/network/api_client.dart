import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'models/answer_submit_response.dart';
import 'models/exam_state.dart';
import 'models/speaking_upload_response.dart';
import 'models/submit_answer_request.dart';
import 'models/timer_sync_response.dart';

/// Thin wrapper over Dio for the exam-delivery endpoints. Converts
/// [DioException] to [ApiException] subtypes so callers (Bloc, sync
/// engine) never need to know about Dio directly.
///
/// Base path: `/api/v1` (set via [AppConfig.apiBaseUrl]).
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Exam attempt lifecycle
  // ---------------------------------------------------------------------------

  Future<ExamState> startAttempt(String examId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/exam-attempts/$examId/start',
      );
      return ExamState.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }

  Future<ExamState> finishAttempt(String attemptId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/exam-attempts/$attemptId/finish',
      );
      return ExamState.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }

  Future<TimerSyncResponse> syncTimer(String attemptId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/exam-attempts/$attemptId/sync-timer',
      );
      return TimerSyncResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Answer submission
  // ---------------------------------------------------------------------------

  /// [idempotencyKey] (e.g. `'$attemptId#$questionId'`, per FR-02/DC-05) is
  /// sent as an `Idempotency-Key` header so a retried flush of the same
  /// answer is treated as a no-op repeat by the server, never a duplicate.
  Future<AnswerSubmitResponse> submitAnswers(
    String attemptId,
    Map<String, dynamic> answers, {
    String? idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/exam-attempts/$attemptId/answers',
        data: answers,
        options: idempotencyKey == null
            ? null
            : Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return AnswerSubmitResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Speaking-specific endpoints
  // ---------------------------------------------------------------------------

  /// Uploads a speaking recording as multipart/form-data.
  ///
  /// [bytes] — raw audio bytes (e.g. from `record` package).
  /// [mimeType] — e.g. `'audio/webm'` on web, `'audio/m4a'` on mobile.
  /// Returns the Cloudinary CDN URL of the uploaded file.
  Future<SpeakingUploadResponse> uploadSpeakingRecording({
    required int attemptId,
    required int questionId,
    required List<int> bytes,
    required String mimeType,
    String filename = 'recording.webm',
  }) async {
    try {
      final formData = FormData.fromMap({
        'questionId': questionId.toString(),
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/exam-attempts/$attemptId/speaking/upload',
        data: formData,
      );
      return SpeakingUploadResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }

  /// Submits a speaking answer (audioUrl) for a specific question.
  Future<void> submitSpeakingAnswer({
    required int attemptId,
    required SubmitAnswerRequest request,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/exam-attempts/$attemptId/answers',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }
}
