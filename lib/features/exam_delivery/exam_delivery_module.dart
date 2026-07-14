import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/dao/answer_outbox_dao.dart';
import '../../core/sync/sync_engine.dart';
import 'data/repositories/exam_attempt_repository.dart';
import 'data/repositories/exam_attempt_repository_impl.dart';
import 'presentation/bloc/exam_attempt_bloc.dart';

/// Registers the exam-delivery feature's DI bindings. Call once at app
/// startup, after `network_module.dart`, `storage_module.dart`, and
/// `sync_module.dart`. Depends only on `core/` services via [GetIt] lookups
/// — never reaches into another feature's internals (file ownership rule).
void registerExamDeliveryModule(GetIt getIt) {
  getIt.registerLazySingleton<ExamAttemptRepository>(
    () => ExamAttemptRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      outboxDao: getIt<AnswerOutboxDao>(),
    ),
  );

  getIt.registerFactory<ExamAttemptBloc>(
    () => ExamAttemptBloc(
      repository: getIt<ExamAttemptRepository>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
}
