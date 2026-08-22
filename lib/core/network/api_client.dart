import 'package:dio/dio.dart';

import 'package:pte_app/core/network/api_exceptions.dart';

/// Thin wrapper over [Dio] used by every feature repository. Callers pass
/// the **full** gateway-relative path (e.g. `/api/iam/auth/login`) — the
/// underlying Dio instance's base URL intentionally excludes `/api`, so
/// omitting it here would 404 at the gateway. Errors are mapped to
/// [ApiException] subtypes here so every call site branches on type, never
/// on a raw status code.
class ApiClient {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _run(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _run(() => _dio.post<T>(path, data: data));
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _run(() => _dio.put<T>(path, data: data));
  }

  /// Submits one buffered answer. **Only `SyncEngine._flushOne` may call
  /// this** — no widget or UI-facing `Bloc` submits an answer directly; the
  /// outbox DAO's `upsertAnswer` is the only write path available to them
  /// (phase-02 Design Constraints). Do not add a shortcut call site.
  ///
  /// A 409 here is remapped from the generic [ConflictException] to
  /// [NotCurrentTaskException]/[ResponseWindowExpiredException] by
  /// inspecting the response body's `message` field — this endpoint-specific
  /// remap, not a change to [_mapError] itself, is what keeps every other
  /// 409 call site's behavior untouched (phase-07 Design Constraints).
  Future<Response<void>> submitAnswer({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String payload,
  }) async {
    try {
      return await post<void>(
        '/api/exam-delivery/attempts/$attemptPublicId/answers',
        data: {'pinnedItemPublicId': pinnedItemPublicId, 'payload': payload},
      );
    } on ConflictException catch (e) {
      throw switch (e.message) {
        'NOT_CURRENT_TASK' => NotCurrentTaskException(e.message),
        'RESPONSE_WINDOW_EXPIRED' => ResponseWindowExpiredException(e.message),
        _ => e,
      };
    }
  }

  Future<Response<T>> _run<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == null) {
      return NetworkException(e.message ?? 'Network error');
    }
    return switch (statusCode) {
      401 || 403 => AuthException('Authentication failed ($statusCode)'),
      400 || 422 => ValidationException('Request rejected ($statusCode)'),
      404 => NotFoundException(_serverMessage(e) ?? 'Not found ($statusCode)'),
      409 => ConflictException(_serverMessage(e) ?? 'Conflict ($statusCode)'),
      429 => RateLimitException('Rate limited ($statusCode)', retryAfter: _retryAfter(e)),
      _ => UnknownApiException('Unexpected response ($statusCode)'),
    };
  }

  /// Extracts the response body's `message` field — the only place the
  /// real `pte-api` distinguishes between the different 409 causes on this
  /// endpoint (HTTP status is identical for all of them).
  String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }

  /// Parses a numeric `Retry-After` header (seconds), the only form the
  /// gateway's rate limiter is expected to send. `null` if absent or in the
  /// HTTP-date form, letting the caller fall back to its own backoff.
  Duration? _retryAfter(DioException e) {
    final header = e.response?.headers.value('retry-after');
    if (header == null) return null;
    final seconds = int.tryParse(header);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
