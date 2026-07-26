import 'dart:async';

import 'package:dio/dio.dart';

import '../token_store.dart';

/// Transparently refreshes an expired access token before retrying any
/// request that failed with 401 — including outbox-flush requests fired
/// by the sync engine (Phase 5) after reconnecting.
///
/// Both the refresh call and the retry run on [refreshDio], a Dio
/// instance with no interceptors attached, so this can never recurse
/// into itself. Concurrent 401s share a single in-flight refresh
/// ([_refreshInFlight]) instead of each calling refresh independently —
/// required because the sync engine can fire several flush requests in
/// quick succession right after the device comes back online.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required this.refreshDio,
    required this.tokenStore,
    required this.refreshEndpoint,
  });

  final Dio refreshDio;
  final TokenStore tokenStore;
  final String refreshEndpoint;

  Future<String>? _refreshInFlight;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(_handleError(err, handler));
  }

  Future<void> _handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await _refreshAccessToken();
      final retried = await _retryWithToken(err.requestOptions, newAccessToken);
      handler.resolve(retried);
    } catch (_) {
      // Refresh itself failed (or the retry failed) — surface the
      // original 401, never loop back into another refresh attempt.
      handler.next(err);
    }
  }

  Future<String> _refreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String> _performRefresh() async {
    final refreshToken = await tokenStore.readRefreshToken();
    final response = await refreshDio.post<Map<String, dynamic>>(
      refreshEndpoint,
      data: {'refresh_token': refreshToken},
    );
    final data = response.data!;
    final newAccessToken = data['access_token'] as String;
    final newRefreshToken = data['refresh_token'] as String;
    await tokenStore.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
    return newAccessToken;
  }

  Future<Response<dynamic>> _retryWithToken(
    RequestOptions options,
    String accessToken,
  ) {
    final retryOptions = options.copyWith(
      headers: {...options.headers, 'Authorization': 'Bearer $accessToken'},
    );
    return refreshDio.fetch<dynamic>(retryOptions);
  }
}
