import 'package:get_it/get_it.dart';

import 'dao/answer_outbox_dao.dart';
import 'drift_database.dart';

/// Registers storage-layer singletons. Call once at app startup, before
/// any feature that depends on [AnswerOutboxDao] (Phase 5 sync engine,
/// Phase 6 Bloc) is constructed.
void registerStorageModule(GetIt getIt) {
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<AnswerOutboxDao>(
    () => AnswerOutboxDao(getIt<AppDatabase>()),
  );
}
