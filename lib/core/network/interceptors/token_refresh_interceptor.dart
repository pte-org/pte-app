import 'dart:async';

import 'package:dio/dio.dart';

import '../token_refresher.dart';

/// Transparently refreshes an expired access token before retrying any
/// request that failed with 401 — including outbox-flush requests fired
/// by the sync engine (Phase 2) after reconnecting.
///
/// The retry runs on [refreshDio], a Dio instance with no interceptors
/// attached, so this can never recurse into itself. The actual refresh
/// call (and its single-flight guard) is owned by [refresher], shared
/// with `ProactiveRefreshScheduler` so both paths can never race each
/// other into two concurrent refresh requests.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required this.refresher,
    required this.refreshDio,
  });

  final TokenRefresher refresher;
  final Dio refreshDio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(_handleError(err, handler));
  }

  Future<void> _handleError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
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

  Future<Response<dynamic>> _retryWithToken(RequestOptions options, String accessToken) {
    final retryOptions = options.copyWith(
      headers: {...options.headers, 'Authorization': 'Bearer $accessToken'},
    );
    return refreshDio.fetch<dynamic>(retryOptions);
  }
}
