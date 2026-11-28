import 'package:get_it/get_it.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/media_repository.dart';
import 'package:pte_app/core/network/media_repository_impl.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/network/raw_upload_client.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/time/server_clock.dart';
import 'package:pte_app/features/exam_attempt/listening/data/audio_player_service_impl.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/data/audio_recorder_service_impl.dart';
import 'package:pte_app/features/exam_attempt/data/attempt_audio_cache.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/audio_prompt_repository_impl.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_code_session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/heartbeat_service.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_service.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';

/// GetIt registration for attempt lifecycle + the session-entry seam.
/// `SessionEntryRepository`'s concrete registration below is the *only*
/// line a different entry mechanism (e.g. a deep link) needs to change
/// (phase-03 Design Constraints).
void setupExamAttemptModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<VolumeService>(() => VolumeService());

  getIt.registerLazySingleton<SessionEntryRepository>(
    () => ExamCodeSessionEntryRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ExamAttemptRepository>(
    () => ExamAttemptRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AudioPromptRepository>(
    () => AudioPromptRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  // TimerService is now anchored to ServerClock (FR-02) so device wall-clock
  // changes cannot extend or shrink the exam deadline. The injection of
  // ServerClock here and the ApiClient's sync-on-every-response logic ensure
  // the timer follows server time, not the local device clock.
  getIt.registerLazySingleton<TimerService>(
    () => TimerService(serverClock: getIt<ServerClock>()),
  );

  // Presence signal for the parallel connectivity-monitoring feature
  // (client-side-exam-timer Phase 4, FR-04) — entirely decoupled from
  // TimerService above.
  getIt.registerLazySingleton<HeartbeatService>(
    () => HeartbeatService(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AudioRecorderService>(
    () => AudioRecorderServiceImpl(),
  );

  // One cache per app run, shared by the bloc (downloads, clears at attempt
  // end) and every listening player (reads). Own unauthenticated Dio.
  getIt.registerLazySingleton<AttemptAudioCache>(() => AttemptAudioCache());

  // Not a singleton: each listening screen's cubit needs its own player
  // instance (one `close()` per task, not shared across tasks) — phase-01
  // Design Constraints. registerFactory gives a fresh instance per get().
  getIt.registerFactory<AudioPlayerService>(
    () => AudioPlayerServiceImpl(
      volumeService: getIt<VolumeService>(),
      audioCache: getIt<AttemptAudioCache>(),
    ),
  );

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
      lockdownService: getIt<LockdownService>(),
      heartbeatService: getIt<HeartbeatService>(),
      audioCache: getIt<AttemptAudioCache>(),
    ),
  );
}
