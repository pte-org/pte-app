import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../storage/dao/answer_outbox_dao.dart';
import '../timer/timer_service.dart';
import 'network_canary.dart';
import 'sync_engine.dart';

/// Registers the sync-layer singletons. Call once at app startup, after
/// `storage_module.dart`, `network_module.dart`, and `timer_module.dart`.
void registerSyncModule(GetIt getIt) {
  getIt.registerLazySingleton<NetworkCanary>(
    () => NetworkCanary(timerService: getIt<TimerService>()),
  );

  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      outboxDao: getIt<AnswerOutboxDao>(),
      apiClient: getIt<ApiClient>(),
      canary: getIt<NetworkCanary>(),
    ),
  );
}
