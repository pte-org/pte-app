import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_strings.dart';
import 'core/storage/dao/answer_outbox_dao.dart';
import 'core/storage/dao/pending_media_upload_dao.dart';
import 'core/sync/media_upload_coordinator.dart';
import 'core/sync/sync_engine.dart';
import 'core/widgets/loading_view.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/device_check/data/device_check_audio_player_impl.dart';
import 'features/device_check/presentation/pages/test_mic_and_sound_screen.dart';
import 'features/exam_attempt/listening/dev/listening_task_preview_screen.dart';
import 'features/exam_attempt/listening/domain/audio_player_service.dart';
import 'features/exam_attempt/reading/dev/reading_task_preview_screen.dart';
import 'features/exam_attempt/reading/presentation/pages/section_completed_screen.dart';
import 'features/exam_attempt/presentation/pages/session_entry_page.dart';
import 'features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';
import 'features/exam_attempt/speaking_writing/dev/speaking_writing_task_preview_screen.dart';
import 'features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'features/host_console/domain/host_access_policy.dart';
import 'features/host_console/presentation/pages/host_console_page.dart';
import 'features/live_proctor/domain/live_proctor_access_policy.dart';
import 'features/live_proctor/presentation/pages/proctor_workspace_page.dart';
import 'features/report/domain/repositories/report_repository.dart';
import 'features/report/presentation/pages/report_screen.dart';

class PteApp extends StatelessWidget {
  const PteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      home: kIsDevSkipAuth
          ? const _DevStandaloneMenu()
          : BlocProvider<AuthBloc>.value(
              value: GetIt.instance<AuthBloc>(),
              child: const AppAuthGate(),
            ),
      routes: kDebugMode
          ? {
              '/dev/reading-preview': (_) => _buildReadingTaskPreviewScreen(),
              '/dev/listening-preview': (_) =>
                  _buildListeningTaskPreviewScreen(),
              '/dev/speaking-writing-preview': (_) =>
                  _buildSpeakingWritingTaskPreviewScreen(),
              '/dev/device-check-preview': (_) => _buildTestMicAndSoundScreen(),
              if (kIsDevSkipAuth) ..._devStandaloneRoutes,
            }
          : const {},
    );
  }

  // Dev-only entry points so each preview screen can be opened without
  // logging in. Never compiled into release builds.
  static const bool kIsDevSkipAuth = bool.fromEnvironment('DEV_SKIP_AUTH');

  static final Map<String, WidgetBuilder> _devStandaloneRoutes = {
    '/dev/standalone': (_) => const _DevStandaloneMenu(),
    '/dev/standalone/reading': (_) => _buildReadingTaskPreviewScreen(),
    '/dev/standalone/listening': (_) => _buildListeningTaskPreviewScreen(),
    '/dev/standalone/speaking-writing': (_) =>
        _buildSpeakingWritingTaskPreviewScreen(),
    '/dev/standalone/device-check': (_) => _buildTestMicAndSoundScreen(),
  };

  static Widget _buildReadingTaskPreviewScreen() {
    final getIt = GetIt.instance;
    return ReadingTaskPreviewScreen(
      outboxDao: getIt<AnswerOutboxDao>(),
      syncEngine: getIt<SyncEngine>(),
      audioRecorderService: getIt<AudioRecorderService>(),
      mediaDao: getIt<PendingMediaUploadDao>(),
      mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
      audioPlayerService: getIt<AudioPlayerService>(),
      examAttemptBloc: getIt<ExamAttemptBloc>(),
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
      examAttemptBloc: getIt<ExamAttemptBloc>(),
    );
  }

  static Widget _buildSpeakingWritingTaskPreviewScreen() {
    final getIt = GetIt.instance;
    return SpeakingWritingTaskPreviewScreen(
      outboxDao: getIt<AnswerOutboxDao>(),
      syncEngine: getIt<SyncEngine>(),
      audioRecorderService: getIt<AudioRecorderService>(),
      mediaDao: getIt<PendingMediaUploadDao>(),
      mediaUploadCoordinator: getIt<MediaUploadCoordinator>(),
      audioPlayerService: getIt<AudioPlayerService>(),
      examAttemptBloc: getIt<ExamAttemptBloc>(),
    );
  }

  static Widget _buildTestMicAndSoundScreen() {
    return TestMicAndSoundScreen(
      recorder: GetIt.instance<AudioRecorderService>(),
      // Not GetIt-registered — single-screen, dev-only feature with no
      // second call site (see TestMicAndSoundScreen's own doc comment).
      player: DeviceCheckAudioPlayerImpl(),
    );
  }
}

class AppAuthGate extends StatelessWidget {
  const AppAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthIdle ||
          state is AuthUnauthenticated ||
          state is AuthError,
      listener: (context, _) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return switch (state) {
            AuthIdle() ||
            AuthUnauthenticated() ||
            AuthError() => const LoginPage(),
            AuthAuthenticating() => const Scaffold(body: LoadingView()),
            AuthAuthenticated(:final claims)
                when HostAccessPolicy.canEnterHostConsole(claims) =>
              const HostConsolePage(),
            AuthAuthenticated(:final claims)
                when LiveProctorAccessPolicy.canControl(claims) =>
              const ProctorWorkspacePage(),
            AuthAuthenticated() => const StudentExamGate(),
          };
        },
      ),
    );
  }
}

/// The real student flow once authenticated: idle/starting/no attempt shows
/// [SessionEntryPage]; [AttemptInProgress] shows the live task via
/// [TaskTypeDispatcher] (keyed on the task, per phase-05 Design
/// Constraints); [AttemptCompleted] shows [SectionCompletedScreen] once,
/// then hands off to [ReportScreen], with a back button (wired through
/// `ReportScreen.onBack`, not a floating overlay — see that class's own
/// doc) to reset [ExamAttemptBloc] and return to [SessionEntryPage] for
/// another session.
class StudentExamGate extends StatefulWidget {
  const StudentExamGate({super.key});

  @override
  State<StudentExamGate> createState() => StudentExamGateState();
}

class StudentExamGateState extends State<StudentExamGate> {
  late ExamAttemptBloc _bloc = GetIt.instance<ExamAttemptBloc>();

  /// Gates `ReportScreen` behind `SectionCompletedScreen` (Screen 7) once
  /// per `AttemptCompleted` — reset alongside `_bloc` on
  /// `_resetToSessionEntry` so the next attempt's completion shows the
  /// interstitial again instead of skipping straight to its report.
  bool _reportRevealed = false;

  void _resetToSessionEntry() {
    final getIt = GetIt.instance;
    getIt.resetLazySingleton<ExamAttemptBloc>(
      disposingFunction: (bloc) => bloc.close(),
    );
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
              audioPlayerService: getIt<AudioPlayerService>(),
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

/// Debug-only landing screen opened at startup when the app is compiled with
/// `--dart-define=DEV_SKIP_AUTH=true`. Lists three buttons that jump straight
/// into the Reading/Listening/Speaking-Writing preview screens, each with
/// their own hand-picked fixtures, with no login flow and no backend
/// dependency. Never reachable in release builds (route only registered when
/// `kIsDevSkipAuth` is true).
class _DevStandaloneMenu extends StatelessWidget {
  const _DevStandaloneMenu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev standalone preview')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Reading preview'),
            subtitle: const Text(
              'Render every reading task type from local fixtures',
            ),
            onTap: () =>
                Navigator.of(context).pushNamed('/dev/standalone/reading'),
          ),
          ListTile(
            leading: const Icon(Icons.headphones),
            title: const Text('Listening preview'),
            subtitle: const Text(
              'Render every listening task type from local fixtures',
            ),
            onTap: () =>
                Navigator.of(context).pushNamed('/dev/standalone/listening'),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Speaking & Writing preview'),
            subtitle: const Text(
              'Render every speaking/writing task type from local fixtures',
            ),
            onTap: () => Navigator.of(
              context,
            ).pushNamed('/dev/standalone/speaking-writing'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_voice),
            title: const Text('Test Mic and Sound'),
            subtitle: const Text(
              'Record + play back your voice, and play a test sound clip',
            ),
            onTap: () =>
                Navigator.of(context).pushNamed('/dev/standalone/device-check'),
          ),
        ],
      ),
    );
  }
}
