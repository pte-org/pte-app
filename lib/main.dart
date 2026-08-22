import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_strings.dart';
import 'core/storage/dao/answer_outbox_dao.dart';
import 'core/storage/dao/pending_media_upload_dao.dart';
import 'core/storage/storage_module.dart';
import 'core/sync/media_upload_coordinator.dart';
import 'core/sync/sync_engine.dart';
import 'features/auth/auth_module.dart';
import 'features/exam_attempt/domain/audio_recorder_service.dart';
import 'features/exam_attempt/dev/reading_task_preview_screen.dart';
import 'features/exam_attempt/exam_attempt_module.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'features/report/report_module.dart';

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
                builder: (context) => FloatingActionButton(
                  onPressed: () => Navigator.of(context).pushNamed('/dev/reading-preview'),
                  child: const Icon(Icons.menu_book),
                ),
              )
            : null,
      ),
      routes: kDebugMode ? {'/dev/reading-preview': (_) => _buildReadingTaskPreviewScreen()} : const {},
    );
  }

  static Widget _buildReadingTaskPreviewScreen() {
    final getIt = GetIt.instance;
    // ExamScaffold's ExamAppBar/ExamBottomBar read ExamAttemptBloc via
    // BlocSelector, so the preview needs one in scope even though this
    // screen never dispatches attempt-lifecycle events against it.
    return BlocProvider.value(
      value: getIt<ExamAttemptBloc>(),
      child: ReadingTaskPreviewScreen(
        outboxDao: getIt<AnswerOutboxDao>(),
        syncEngine: getIt<SyncEngine>(),
        audioRecorderService: getIt<AudioRecorderService>(),
        mediaDao: getIt<PendingMediaUploadDao>(),
        mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
      ),
    );
  }
}
