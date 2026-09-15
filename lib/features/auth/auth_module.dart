import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/interceptors/auth_header_interceptor.dart';
import 'package:pte_app/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:pte_app/core/network/proactive_refresh_scheduler.dart';
import 'package:pte_app/core/network/token_refresher.dart';
import 'package:pte_app/core/storage/token_store.dart';
import 'package:pte_app/dev/mock_backend/mock_backend_adapter.dart';
import 'package:pte_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';

/// GetIt registration for auth + the shared networking primitives every
/// later feature module depends on (`ApiClient`, `TokenStore`). Real-module
/// counterpart to Phase 0's `_example_module.dart` template.
Dio _newGatewayDio() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.gatewayBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    sendTimeout: AppConfig.sendTimeout,
  ));
  if (AppConfig.useMockBackend) {
    dio.httpClientAdapter = MockBackendAdapter.shared;
  }
  return dio;
}

void setupAuthModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<TokenStore>(() => TokenStore(secureStorage: getIt()));

  // refreshDio: no interceptors, so the refresh call and its retry can
  // never recurse into TokenRefreshInterceptor.
  getIt.registerLazySingleton<TokenRefresher>(
    () => TokenRefresher(
      refreshDio: _newGatewayDio(),
      tokenStore: getIt(),
      refreshEndpoint: '/api/iam/auth/refresh',
    ),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      dio: _newGatewayDio()
        ..interceptors.add(AuthHeaderInterceptor(tokenStore: getIt()))
        ..interceptors.add(TokenRefreshInterceptor(refresher: getIt())),
    ),
  );

  getIt.registerLazySingleton<ProactiveRefreshScheduler>(
    () => ProactiveRefreshScheduler(
      tokenStore: getIt(),
      onRefreshDue: () => getIt<TokenRefresher>().refresh(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiClient: getIt(), tokenStore: getIt()),
  );

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(repository: getIt(), scheduler: getIt()),
  );
}
