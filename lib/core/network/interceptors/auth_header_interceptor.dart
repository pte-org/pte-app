import 'package:dio/dio.dart';

import 'package:pte_app/core/storage/token_store.dart';

/// Attaches the current access token as a Bearer header on every outgoing
/// request. Without this, every protected request would 401 on its first
/// attempt regardless of token freshness, defeating the point of
/// `ProactiveRefreshScheduler` (QUAL-001, Phase 1 quality gate).
class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor({required this.tokenStore});

  final TokenStore tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = tokenStore.accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}
