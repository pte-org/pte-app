import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/host_user_repository_impl.dart';
import 'domain/repositories/host_user_repository.dart';
import 'domain/usecases/load_host_users.dart';

void setupHostUsersModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<HostUserRepository>(
    () => HostUserRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<LoadHostUsers>(
    () => LoadHostUsers(repository: getIt<HostUserRepository>()),
  );
}
