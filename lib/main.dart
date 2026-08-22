import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/storage/storage_module.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/auth/auth_module.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/listening/dev/listening_task_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/reading_task_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/exam_attempt_module.dart';
import 'package:pte_app/features/report/report_module.dart';

void main() {
  setupAuthModule();
  setupStorageModule();
  setupExamAttemptModule();
  setupReportModule();
  runApp(const PteApp());
}

class PteApp extends StatelessWidget {
  const PteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      home: Scaffold(
        body: Center(child: Text(AppStrings.appTitle)),
        floatingActionButton: kDebugMode
            ? Builder(
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'dev-reading-preview',
                      onPressed: () => Navigator.of(context).pushNamed('/dev/reading-preview'),
                      child: const Icon(Icons.menu_book),
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    FloatingActionButton(
                      heroTag: 'dev-listening-preview',
                      onPressed: () => Navigator.of(context).pushNamed('/dev/listening-preview'),
                      child: const Icon(Icons.headphones),
                    ),
                  ],
                ),
              )
            : null,
      ),
      routes: kDebugMode
          ? {
              '/dev/reading-preview': (_) => _buildReadingTaskPreviewScreen(),
              '/dev/listening-preview': (_) => _buildListeningTaskPreviewScreen(),
            }
          : const {},
    );
  }

  static Widget _buildReadingTaskPreviewScreen() {
    final getIt = GetIt.instance;
    return ReadingTaskPreviewScreen(
      outboxDao: getIt<AnswerOutboxDao>(),
      syncEngine: getIt<SyncEngine>(),
      audioRecorderService: getIt<AudioRecorderService>(),
      mediaDao: getIt<PendingMediaUploadDao>(),
      mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
      audioPlayerService: getIt<AudioPlayerService>(),
    );
  }

  static Widget _buildListeningTaskPreviewScreen() {
    final getIt = GetIt.instance;
    return ListeningTaskPreviewScreen(
      outboxDao: getIt<AnswerOutboxDao>(),
      syncEngine: getIt<SyncEngine>(),
      audioRecorderService: getIt<AudioRecorderService>(),
      mediaDao: getIt<PendingMediaUploadDao>(),
      mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
      audioPlayerService: getIt<AudioPlayerService>(),
    );
  }
}
