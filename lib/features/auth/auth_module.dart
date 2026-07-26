import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/interceptors/auth_header_interceptor.dart';
import '../../core/network/interceptors/token_refresh_interceptor.dart';
import '../../core/network/proactive_refresh_scheduler.dart';
import '../../core/network/token_refresher.dart';
import '../../core/storage/token_store.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/bloc/auth_bloc.dart';

/// GetIt registration for auth + the shared networking primitives every
/// later feature module depends on (`ApiClient`, `TokenStore`). Real-module
/// counterpart to Phase 0's `_example_module.dart` template.
void setupAuthModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<TokenStore>(() => TokenStore(secureStorage: getIt()));

  // refreshDio: no interceptors, so the refresh call and its retry can
  // never recurse into TokenRefreshInterceptor.
  final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.gatewayBaseUrl));
  getIt.registerLazySingleton<TokenRefresher>(
    () => TokenRefresher(
      refreshDio: refreshDio,
      tokenStore: getIt(),
      refreshEndpoint: '/api/iam/auth/refresh',
    ),
  );

  final dio = Dio(BaseOptions(baseUrl: AppConfig.gatewayBaseUrl))
    ..interceptors.add(AuthHeaderInterceptor(tokenStore: getIt()))
    ..interceptors.add(TokenRefreshInterceptor(refresher: getIt()));
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dio: dio));

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
    () => AuthBloc(repository: getIt(), tokenStore: getIt(), scheduler: getIt()),
  );
}
