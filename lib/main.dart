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
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/exam_attempt/domain/audio_recorder_service.dart';
import 'features/exam_attempt/dev/reading_task_preview_screen.dart';
import 'features/exam_attempt/exam_attempt_module.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'features/exam_attempt/presentation/pages/session_entry_page.dart';
import 'features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';
import 'features/report/domain/repositories/report_repository.dart';
import 'features/report/presentation/pages/report_screen.dart';
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
      home: Stack(
        children: [
          BlocProvider.value(value: GetIt.instance<AuthBloc>(), child: const _AuthGate()),
          // Debug-only shortcut into the fixture-driven reading preview
          // (main.dart's original entry point) — layered above the real
          // login/session/task flow so both stay reachable while testing.
          if (kDebugMode)
            Positioned(
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: Builder(
                  builder: (context) => FloatingActionButton(
                    heroTag: 'dev-reading-preview-entry',
                    onPressed: () => Navigator.of(context).pushNamed('/dev/reading-preview'),
                    child: const Icon(Icons.menu_book),
                  ),
                ),
              ),
            ),
        ],
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

/// Root of the real (non-preview) flow: unauthenticated shows [LoginPage];
/// once `AuthBloc` reaches [AuthAuthenticated] it hands off to
/// [_ExamGate]. No navigator/route stack involved — each gate just swaps
/// its child based on its bloc's current state, same shape as the dev
/// preview screen's own internal `_selected` switch.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const _ExamGate();
        }
        return const LoginPage();
      },
    );
  }
}

/// Second half of the gate chain: idle/starting/no attempt shows
/// [SessionEntryPage]; [AttemptInProgress] shows the live task via
/// [TaskTypeDispatcher] (keyed on the task, per phase-05 Design
/// Constraints); [AttemptCompleted] hands off to [ReportScreen].
class _ExamGate extends StatelessWidget {
  const _ExamGate();

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return BlocProvider.value(
      value: getIt<ExamAttemptBloc>(),
      child: BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
        builder: (context, state) {
          if (state is AttemptInProgress) {
            return TaskTypeDispatcher(
              task: state.task,
              attemptPublicId: state.attemptPublicId,
              outboxDao: getIt<AnswerOutboxDao>(),
              syncEngine: getIt<SyncEngine>(),
              audioRecorderService: getIt<AudioRecorderService>(),
              mediaDao: getIt<PendingMediaUploadDao>(),
              mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
            );
          }
          if (state is AttemptCompleted) {
            return ReportScreen(attemptPublicId: state.attemptPublicId, repository: getIt<ReportRepository>());
          }
          return const SessionEntryPage();
        },
      ),
    );
  }
}
