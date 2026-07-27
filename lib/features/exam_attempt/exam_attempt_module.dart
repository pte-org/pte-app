import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/sync/sync_engine.dart';
import 'data/repositories/exam_attempt_repository_impl.dart';
import 'data/repositories/manual_session_entry_repository.dart';
import 'domain/repositories/exam_attempt_repository.dart';
import 'domain/repositories/session_entry_repository.dart';
import 'presentation/bloc/exam_attempt_bloc.dart';

/// GetIt registration for attempt lifecycle + the placeholder session-entry
/// seam. `SessionEntryRepository`'s concrete registration below is the
/// *only* line Member 3's eventual replacement needs to change (phase-03
/// Design Constraints).
void setupExamAttemptModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<SessionEntryRepository>(() => const ManualSessionEntryRepository());

  getIt.registerLazySingleton<ExamAttemptRepository>(
    () => ExamAttemptRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ExamAttemptBloc>(
    () => ExamAttemptBloc(
      repository: getIt(),
      sessionEntryRepository: getIt(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
}
