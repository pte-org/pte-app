import 'package:dio/dio.dart';

import 'package:pte_app/core/config/app_config.dart';
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

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _run<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: headers == null ? null : Options(headers: headers),
      ),
    );
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _run<T>(() => _dio.post<dynamic>(path, data: data));
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _run<T>(() => _dio.put<dynamic>(path, data: data));
  }

  /// Submits one buffered answer. **Only `SyncEngine._flushOne` may call
  /// this** — no widget or UI-facing `Bloc` submits an answer directly; the
  /// outbox DAO's `upsertAnswer` is the only write path available to them
  /// (phase-02 Design Constraints). Do not add a shortcut call site.
  ///
  /// A 409 here is remapped from the generic [ConflictException] to
  /// [NotCurrentTaskException] by inspecting the response body's `message`
  /// field — this endpoint-specific remap, not a change to [_mapError]
  /// itself, is what keeps every other 409 call site's behavior untouched
  /// (phase-07 Design Constraints). Used to also remap `RESPONSE_WINDOW_EXPIRED`
  /// to a dedicated exception type — removed (client-side-exam-timer Phase 7)
  /// once the server-side exception producing that message was deleted in
  /// Phase 5; the server can no longer send it.
  Future<Response<void>> submitAnswer({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String payload,
  }) async {
    try {
      return await post<void>(
        '${AppConfig.examAttemptsPath}/$attemptPublicId/answers',
        data: {'pinnedItemPublicId': pinnedItemPublicId, 'payload': payload},
      );
    } on ConflictException catch (e) {
      throw switch (e.message) {
        'NOT_CURRENT_TASK' => NotCurrentTaskException(e.message),
        _ => e,
      };
    }
  }

  /// The pinned item's on-demand play — `pte-api`'s `/audio` endpoint. A 403
  /// is remapped from the generic [ForbiddenException] to
  /// [ReplayLimitExceededException], and a 410 from [GoneException] to
  /// [AudioUrlExpiredException], by inspecting the response body's `message`
  /// field — same endpoint-specific-remap pattern as [submitAnswer], so
  /// every other 403/410 call site's behavior stays untouched
  /// (plans/phat-speaking-audio-prompt-e2e). [playRequestId] is a
  /// client-generated UUID per play attempt — the server replays the same
  /// outcome for a repeated id instead of re-incrementing its play count.
  Future<String> playAudio({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String playRequestId,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '${AppConfig.examAttemptsPath}/$attemptPublicId/items/$pinnedItemPublicId/audio',
        headers: {'X-Play-Request-Id': playRequestId},
      );
      return response.data!['audioUrl'] as String;
    } on ForbiddenException catch (e) {
      throw switch (e.message) {
        'REPLAY_LIMIT_EXCEEDED' => ReplayLimitExceededException(e.message),
        _ => e,
      };
    } on GoneException catch (e) {
      throw switch (e.message) {
        'AUDIO_URL_EXPIRED' => AudioUrlExpiredException(e.message),
        _ => e,
      };
    }
  }

  /// STRICT-integrity counterpart to [submitAnswer] — used only when the
  /// attempt's pinned `answerIntegrityLevel == STRICT`. Same **only
  /// `SyncEngine._flushOne` may call this** constraint and same 409-remap
  /// behavior as [submitAnswer]; only the endpoint and body shape differ.
  Future<Response<void>> submitEncryptedAnswer({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String wrappedKey,
    required String iv,
    required String ciphertext,
  }) async {
    try {
      return await post<void>(
        '${AppConfig.examAttemptsPath}/$attemptPublicId/answers/encrypted',
        data: {
          'pinnedItemPublicId': pinnedItemPublicId,
          'wrappedKey': wrappedKey,
          'iv': iv,
          'ciphertext': ciphertext,
        },
      );
    } on ConflictException catch (e) {
      throw switch (e.message) {
        'NOT_CURRENT_TASK' => NotCurrentTaskException(e.message),
        _ => e,
      };
    }
  }

  /// Presence signal for the parallel connectivity-monitoring feature
  /// (client-side-exam-timer Phase 4, FR-04) — carries no timer/deadline/task
  /// data, replacing the former `fetchTimerState`'s incidental role as a
  /// heartbeat carrier (that endpoint was already unused by `TimerService`
  /// as of Phase 3, and was deleted server-side and here in Phase 5/7). No
  /// endpoint-specific error remap, unlike [submitAnswer]/[playAudio] —
  /// every failure mode here is the caller's (`HeartbeatService`) concern to
  /// swallow identically (log, retry next interval), per this phase's own
  /// Risk mitigation: never surfaced to the student, never affecting the
  /// exam flow.
  Future<Response<void>> sendHeartbeat(String attemptPublicId) {
    return post<void>(
      '${AppConfig.examAttemptsPath}/$attemptPublicId/heartbeat',
    );
  }

  Future<Response<T>> _run<T>(Future<Response<dynamic>> Function() call) async {
    try {
      return _asTypedResponse<T>(await call());
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// The real gateway wraps every response body in `pte-common`'s
  /// `ApiResponse<T>` envelope (`{success, data, message}`) — every
  /// `fromJson()` call site in this app is written against the inner
  /// `data` payload directly, so unwrap it here once instead of at every
  /// call site. Guarded on all three envelope keys so a body that doesn't
  /// look like the envelope (e.g. a test double stubbed with flat data)
  /// passes through untouched.
  Response<T> _asTypedResponse<T>(Response<dynamic> response) {
    final body = response.data;
    final payload =
        body is Map<String, dynamic> &&
            body.containsKey('success') &&
            body.containsKey('data') &&
            body.containsKey('message')
        ? body['data']
        : body;

    return Response<T>(
      data: payload as T?,
      headers: response.headers,
      requestOptions: response.requestOptions,
      isRedirect: response.isRedirect,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      extra: response.extra,
      redirects: response.redirects,
    );
  }

  ApiException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == null) {
      return NetworkException(e.message ?? 'Network error');
    }
    return switch (statusCode) {
      401 => const AuthException('Authentication failed (401)'),
      // `_serverMessage` distinguishes a genuine permission failure from a
      // specific-cause 403 an endpoint-specific remap wants to inspect (e.g.
      // `ApiClient.playAudio`'s `REPLAY_LIMIT_EXCEEDED`) — same reason 409
      // already captures it below.
      403 => ForbiddenException(_serverMessage(e) ?? 'Permission denied (403)'),
      400 || 422 => ValidationException('Request rejected ($statusCode)'),
      404 => NotFoundException(_serverMessage(e) ?? 'Not found ($statusCode)'),
      409 => ConflictException(_serverMessage(e) ?? 'Conflict ($statusCode)'),
      410 => GoneException(_serverMessage(e) ?? 'Gone ($statusCode)'),
      429 => RateLimitException(
        'Rate limited ($statusCode)',
        retryAfter: _retryAfter(e),
      ),
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
