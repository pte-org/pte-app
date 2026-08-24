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
import 'features/exam_attempt/exam_attempt_module.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'features/exam_attempt/presentation/pages/section_completed_screen.dart';
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
      debugShowCheckedModeBanner: false,
      home: BlocProvider.value(value: GetIt.instance<AuthBloc>(), child: const _AuthGate()),
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
/// Constraints); [AttemptCompleted] hands off to [ReportScreen], with a
/// floating back button (dev-testing affordance, same pattern as the
/// reading-preview screen's) to reset [ExamAttemptBloc] and return to
/// [SessionEntryPage] for another session — [AttemptCompleted] has no
/// bloc event of its own to unwind it otherwise.
class _ExamGate extends StatefulWidget {
  const _ExamGate();

  @override
  State<_ExamGate> createState() => _ExamGateState();
}

class _ExamGateState extends State<_ExamGate> {
  late ExamAttemptBloc _bloc = GetIt.instance<ExamAttemptBloc>();

  /// Gates `ReportScreen` behind `SectionCompletedScreen` (Screen 7) once
  /// per `AttemptCompleted` — reset alongside `_bloc` on
  /// `_resetToSessionEntry` so the next attempt's completion shows the
  /// interstitial again instead of skipping straight to its report.
  bool _reportRevealed = false;

  void _resetToSessionEntry() {
    final getIt = GetIt.instance;
    getIt.resetLazySingleton<ExamAttemptBloc>(disposingFunction: (bloc) => bloc.close());
    setState(() {
      _bloc = getIt<ExamAttemptBloc>();
      _reportRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return BlocProvider.value(
      value: _bloc,
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
            if (!_reportRevealed) {
              return SectionCompletedScreen(
                timeExpired: state.timeExpired,
                onContinue: () => setState(() => _reportRevealed = true),
              );
            }
            return ReportScreen(
              attemptPublicId: state.attemptPublicId,
              repository: getIt<ReportRepository>(),
              onBack: _resetToSessionEntry,
            );
          }
          return const SessionEntryPage();
        },
      ),
    );
  }
}
