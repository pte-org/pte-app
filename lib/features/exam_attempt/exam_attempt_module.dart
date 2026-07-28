import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/network/media_repository.dart';
import '../../core/network/media_repository_impl.dart';
import '../../core/network/network_canary.dart';
import '../../core/network/raw_upload_client.dart';
import '../../core/storage/dao/answer_outbox_dao.dart';
import '../../core/storage/dao/pending_media_upload_dao.dart';
import '../../core/sync/media_upload_coordinator.dart';
import '../../core/sync/sync_engine.dart';
import 'data/audio_recorder_service_impl.dart';
import 'data/repositories/exam_attempt_repository_impl.dart';
import 'data/repositories/manual_session_entry_repository.dart';
import 'data/repositories/timer_repository_impl.dart';
import 'domain/audio_recorder_service.dart';
import 'domain/repositories/exam_attempt_repository.dart';
import 'domain/repositories/session_entry_repository.dart';
import 'domain/repositories/timer_repository.dart';
import 'domain/timer_service.dart';
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

  getIt.registerLazySingleton<TimerRepository>(
    () => TimerRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<TimerService>(
    () => TimerService(timerRepository: getIt<TimerRepository>()),
  );

  getIt.registerLazySingleton<AudioRecorderService>(() => AudioRecorderServiceImpl());

  getIt.registerLazySingleton<MediaRepository>(
    () => MediaRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  // No interceptors, ever — the presigned URL is the credential, not the
  // app's bearer token (phase-06 Design Constraints). Never share
  // ApiClient's gateway Dio instance for this.
  getIt.registerLazySingleton<RawUploadClient>(() => RawUploadClient());

  getIt.registerLazySingleton<MediaUploadCoordinator>(
    () => MediaUploadCoordinator(
      mediaDao: getIt<PendingMediaUploadDao>(),
      outboxDao: getIt<AnswerOutboxDao>(),
      mediaRepository: getIt<MediaRepository>(),
      rawUploadClient: getIt<RawUploadClient>(),
      canary: getIt<NetworkCanary>(),
      // Explicit, not the constructor's own default — a single source of
      // truth with the recorder's actual AudioEncoder, so the two can
      // never silently drift out of sync.
      contentType: readAloudContentType,
    ),
  );

  getIt.registerLazySingleton<ExamAttemptBloc>(
    () => ExamAttemptBloc(
      repository: getIt(),
      sessionEntryRepository: getIt(),
      syncEngine: getIt<SyncEngine>(),
      timerService: getIt<TimerService>(),
      mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
    ),
  );
}
