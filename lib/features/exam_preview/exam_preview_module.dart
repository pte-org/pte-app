import 'package:get_it/get_it.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/listening/data/audio_player_service_impl.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/data/audio_recorder_service_impl.dart';

import 'data/preview_audio_session.dart';
import 'data/repositories/host_exam_preview_repository_impl.dart';
import 'domain/repositories/host_exam_preview_repository.dart';

void setupExamPreviewModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<HostExamPreviewRepository>(
    () => HostExamPreviewRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerFactory<PreviewAudioSession>(
    () => PreviewAudioSession(
      player: AudioPlayerServiceImpl(volumeService: getIt<VolumeService>()),
      recorder: AudioRecorderServiceImpl(),
    ),
  );
}
