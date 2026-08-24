import 'package:dio/dio.dart';

import 'package:pte_app/core/storage/token_store.dart';

/// Single-flight token refresh, shared by [TokenRefreshInterceptor]
/// (reactive, 401-triggered) and `ProactiveRefreshScheduler` (proactive,
/// pre-expiry) — both paths must never issue two concurrent refresh
/// requests, so the guard lives here once instead of being duplicated.
class TokenRefresher {
  TokenRefresher({
    required this.refreshDio,
    required this.tokenStore,
    required this.refreshEndpoint,
  });

  final Dio refreshDio;
  final TokenStore tokenStore;
  final String refreshEndpoint;

  Future<String>? _refreshInFlight;

  Future<String> refresh() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String> _performRefresh() async {
    final refreshToken = await tokenStore.readRefreshToken();
    final response = await refreshDio.post<Map<String, dynamic>>(
      refreshEndpoint,
      data: {'refreshToken': refreshToken},
    );
    final body = response.data!;
    // Same `ApiResponse<T>` envelope `ApiClient._unwrapEnvelope` strips —
    // duplicated inline rather than shared, since refreshDio deliberately
    // carries zero interceptors (see class doc) and bypasses `ApiClient`
    // entirely.
    final data = body.containsKey('success') ? body['data'] as Map<String, dynamic> : body;
    final newAccessToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String;
    final expiresInSeconds = data['expiresInSeconds'] as int;
    await tokenStore.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresInSeconds: expiresInSeconds,
    );
    return newAccessToken;
  }
}
