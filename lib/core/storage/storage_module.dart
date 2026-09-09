import 'package:get_it/get_it.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/local_violation_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';

/// GetIt registration for the offline answer outbox and its background
/// sync engine — shared infrastructure Phase 3 onward starts/stops via the
/// exam-delivery `Bloc`'s lifecycle (phase-02 Design Constraints).
void setupStorageModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<AnswerOutboxDao>(() => getIt<AppDatabase>().answerOutboxDao);
  getIt.registerLazySingleton<PendingMediaUploadDao>(() => getIt<AppDatabase>().pendingMediaUploadDao);
  getIt.registerLazySingleton<LocalViolationDao>(() => getIt<AppDatabase>().localViolationDao);
  getIt.registerLazySingleton<NetworkCanary>(() => NetworkCanary());

  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      outboxDao: getIt(),
      apiClient: getIt<ApiClient>(),
      canary: getIt(),
    ),
  );
}
