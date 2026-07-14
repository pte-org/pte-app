import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'dio_client.dart';
import 'interceptors/token_refresh_interceptor.dart';
import 'token_store.dart';

/// Registers network-layer singletons. Call once at app startup, after
/// [AppConfig] is available and before any feature that depends on
/// [ApiClient] (Phase 5 sync engine, Phase 6 Bloc) is constructed.
void registerNetworkModule(GetIt getIt, AppConfig config) {
  getIt.registerLazySingleton<AppConfig>(() => config);
  getIt.registerLazySingleton<TokenStore>(InMemoryTokenStore.new);

  getIt.registerLazySingleton<Dio>(
    () => createRefreshDio(config),
    instanceName: 'refreshDio',
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = createDio(config);
    dio.interceptors.add(
      TokenRefreshInterceptor(
        refreshDio: getIt<Dio>(instanceName: 'refreshDio'),
        tokenStore: getIt<TokenStore>(),
        refreshEndpoint: '/auth/refresh',
      ),
    );
    return dio;
  });

  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));
}
