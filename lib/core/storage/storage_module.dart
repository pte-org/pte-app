import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../network/network_canary.dart';
import '../sync/sync_engine.dart';
import 'app_database.dart';
import 'dao/answer_outbox_dao.dart';

/// GetIt registration for the offline answer outbox and its background
/// sync engine — shared infrastructure Phase 3 onward starts/stops via the
/// exam-delivery `Bloc`'s lifecycle (phase-02 Design Constraints).
void setupStorageModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<AnswerOutboxDao>(() => getIt<AppDatabase>().answerOutboxDao);
  getIt.registerLazySingleton<NetworkCanary>(() => NetworkCanary());

  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      outboxDao: getIt(),
      apiClient: getIt<ApiClient>(),
      canary: getIt(),
    ),
  );
}
