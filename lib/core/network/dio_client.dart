import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Builds the app's primary Dio instance (interceptors attached by the
/// caller, e.g. [TokenRefreshInterceptor] via `network_module.dart`).
Dio createDio(AppConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
}

/// Builds a Dio instance with no interceptors attached — used exclusively
/// for the token-refresh call and its retry, so refresh can never recurse
/// into [TokenRefreshInterceptor].
Dio createRefreshDio(AppConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
}
