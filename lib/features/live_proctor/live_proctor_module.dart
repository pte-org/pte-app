import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';
import 'data/repositories/live_proctor_repository_impl.dart';
import 'data/transport/stomp_live_proctor_transport.dart';
import 'domain/live_proctor_transport.dart';
import 'domain/repositories/live_proctor_repository.dart';
import 'presentation/bloc/assigned_sessions_bloc.dart';
import 'presentation/bloc/live_proctor_bloc.dart';

void setupLiveProctorModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<LiveProctorRepository>(
    () => LiveProctorRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerFactory<LiveProctorTransport>(StompLiveProctorTransport.new);
  getIt.registerFactory<AssignedSessionsBloc>(
    () => AssignedSessionsBloc(repository: getIt<LiveProctorRepository>()),
  );
  getIt.registerFactory<LiveProctorBloc>(
    () => LiveProctorBloc(
      repository: getIt<LiveProctorRepository>(),
      transport: getIt<LiveProctorTransport>(),
      readAccessToken: () => getIt<TokenStore>().accessToken,
    ),
  );
}
