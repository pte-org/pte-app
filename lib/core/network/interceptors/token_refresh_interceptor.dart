import 'dart:async';

import 'package:dio/dio.dart';

import 'package:pte_app/core/network/token_refresher.dart';

/// Transparently refreshes an expired access token before retrying any
/// request that failed with 401 — including outbox-flush requests fired
/// by the sync engine (Phase 2) after reconnecting.
///
/// The retry runs on [refresher]'s [TokenRefresher.refreshDio] — the one
/// and only Dio instance with no interceptors attached, so this can never
/// recurse into itself. There is deliberately no second `refreshDio` field
/// here: owning it in exactly one place (`TokenRefresher`) is what
/// guarantees the interceptor and the proactive scheduler can never end up
/// retrying against a different, interceptor-laden Dio instance
/// (QUAL-002, Phase 1 quality gate).
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({required this.refresher});

  final TokenRefresher refresher;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(_handleError(err, handler));
  }

  Future<void> _handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        _isAuthEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await refresher.refresh();
      final retried = await _retryWithToken(err.requestOptions, newAccessToken);
      handler.resolve(retried);
    } catch (_) {
      // Refresh itself failed (or the retry failed) — surface the
      // original 401, never loop back into another refresh attempt.
      handler.next(err);
    }
  }

  /// A 401 from these calls answers the credentials in the request itself (a wrong password, a dead refresh
  /// token), not an expired access token, so refreshing would only add a doomed round trip — and, with a leftover
  /// refresh token on the device, could rotate it and replay the login.
  static const List<String> _authPaths = [
    '/auth/login',
    '/auth/refresh',
    '/auth/logout',
  ];

  static bool _isAuthEndpoint(String path) => _authPaths.any(path.contains);

  Future<Response<dynamic>> _retryWithToken(
    RequestOptions options,
    String accessToken,
  ) {
    final retryOptions = options.copyWith(
      headers: {...options.headers, 'Authorization': 'Bearer $accessToken'},
    );
    return refresher.refreshDio.fetch<dynamic>(retryOptions);
  }
}
