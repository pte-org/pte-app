import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_dimensions.dart';
import 'core/constants/app_typography.dart';
import 'core/security/lockdown_service.dart';
import 'core/storage/dao/answer_outbox_dao.dart';
import 'core/storage/dao/pending_media_upload_dao.dart';
import 'core/sync/media_upload_coordinator.dart';
import 'core/sync/sync_engine.dart';
import 'core/widgets/loading_view.dart';
import 'core/widgets/primary_button.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/device_check/data/device_check_audio_player_impl.dart';
import 'features/device_check/presentation/pages/test_mic_and_sound_screen.dart';
import 'features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'features/exam_attempt/constants/exam_attempt_error_message.dart';
import 'features/exam_attempt/constants/exam_attempt_strings.dart';
import 'features/exam_attempt/dev/api_mock_exam_preview_screen.dart';
import 'features/exam_attempt/listening/dev/listening_task_preview_screen.dart';
import 'features/exam_attempt/listening/domain/audio_player_service.dart';
import 'features/exam_attempt/dev/exam_ui_preview_screen.dart';
import 'features/exam_attempt/reading/dev/reading_task_preview_screen.dart';
import 'features/exam_attempt/reading/presentation/pages/section_completed_screen.dart';
import 'features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';
import 'features/exam_attempt/presentation/widgets/lockdown_activation_failure_dialog.dart';
import 'features/exam_attempt/speaking_writing/dev/speaking_writing_task_preview_screen.dart';
import 'features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
      ),
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
              '/dev/exam-ui-preview': (_) => const ExamUiPreviewScreen(),
              '/dev/api-mock-exam': (_) => ApiMockExamPreviewScreen(
                repository: GetIt.instance<ExamAttemptRepository>(),
                audioPromptRepository: GetIt.instance<AudioPromptRepository>(),
                audioPlayerService: GetIt.instance<AudioPlayerService>(),
              ),
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
    '/dev/standalone/exam-ui': (_) => const ExamUiPreviewScreen(),
    '/dev/standalone/api-mock-exam': (_) => ApiMockExamPreviewScreen(
      repository: GetIt.instance<ExamAttemptRepository>(),
      audioPromptRepository: GetIt.instance<AudioPromptRepository>(),
      audioPlayerService: GetIt.instance<AudioPlayerService>(),
    ),
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
      audioPromptRepository: getIt<AudioPromptRepository>(),
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
      audioPromptRepository: getIt<AudioPromptRepository>(),
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
      audioPromptRepository: getIt<AudioPromptRepository>(),
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

class AppAuthGate extends StatefulWidget {
  const AppAuthGate({super.key});

  @override
  State<AppAuthGate> createState() => _AppAuthGateState();
}

class _AppAuthGateState extends State<AppAuthGate> {
  String? _sessionIdForStudent;

  void _rememberSessionId(String value) {
    final normalized = value.trim();
    _sessionIdForStudent = normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthIdle ||
          state is AuthUnauthenticated ||
          state is AuthError,
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          _sessionIdForStudent = null;
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return switch (state) {
            AuthIdle() ||
            AuthUnauthenticated() ||
            AuthError() => LoginPage(
              requireSessionId: true,
              onSessionIdProvided: _rememberSessionId,
            ),
            // Keep the same required-session login form mounted while the
            // authentication request is in progress.
            AuthAuthenticating() => LoginPage(
              requireSessionId: true,
              onSessionIdProvided: _rememberSessionId,
            ),
            AuthAuthenticated(:final claims)
                when HostAccessPolicy.canEnterHostConsole(claims) =>
              const HostConsolePage(),
            AuthAuthenticated(:final claims)
                when LiveProctorAccessPolicy.canControl(claims) =>
              const ProctorWorkspacePage(),
            AuthAuthenticated() when _sessionIdForStudent == null => LoginPage(
              requireSessionId: true,
              onSessionIdProvided: _rememberSessionId,
            ),
            AuthAuthenticated() => StudentExamGate(
              initialSessionId: _sessionIdForStudent!,
            ),
          };
        },
      ),
    );
  }
}

/// The student exam flow starts the session ID captured from login.
/// [AttemptInProgress] shows the live task via
/// [TaskTypeDispatcher] (keyed on the task, per phase-05 Design
/// Constraints); [AttemptCompleted] shows [SectionCompletedScreen] once,
/// then hands off to [ReportScreen], with a back button (wired through
/// `ReportScreen.onBack`, not a floating overlay — see that class's own
/// doc) to reset [ExamAttemptBloc] and return to login for another session.
class StudentExamGate extends StatefulWidget {
  const StudentExamGate({super.key, required this.initialSessionId});

  final String initialSessionId;

  @override
  State<StudentExamGate> createState() => StudentExamGateState();
}

class StudentExamGateState extends State<StudentExamGate> {
  late ExamAttemptBloc _bloc = GetIt.instance<ExamAttemptBloc>();
  bool _attemptStarted = false;
  bool _deviceCheckConfirmed = false;

  /// Gates `ReportScreen` behind `SectionCompletedScreen` (Screen 7) once
  /// per `AttemptCompleted` — reset alongside `_bloc` on
  /// `_resetToLogin` so the next attempt's completion shows the
  /// interstitial again instead of skipping straight to its report.
  bool _reportRevealed = false;

  @override
  void initState() {
    super.initState();
    final sessionId = widget.initialSessionId.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bloc.add(SessionResolutionRequested(rawInput: sessionId));
    });
  }

  void _resetToLogin() {
    final getIt = GetIt.instance;
    getIt.resetLazySingleton<ExamAttemptBloc>(
      disposingFunction: (bloc) => bloc.close(),
    );
    _bloc = getIt<ExamAttemptBloc>();
    _attemptStarted = false;
    _deviceCheckConfirmed = false;
    _reportRevealed = false;
    context.read<AuthBloc>().add(const LogoutRequested());
  }

  void _retrySession() {
    _bloc.add(
      SessionResolutionRequested(
        rawInput: widget.initialSessionId.trim(),
        deviceCheckConfirmed: _deviceCheckConfirmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ExamAttemptBloc, ExamAttemptState>(
        listener: (context, state) {
          if (state is AttemptInProgress || state is AttemptCompleted) {
            _attemptStarted = true;
          }
          if (state is AttemptInProgress) {
            _deviceCheckConfirmed = true;
            _reportRevealed = false;
          }
          final error = state is AttemptError ? state.error : null;
          if (error is LockdownActivationException) {
            LockdownActivationFailureDialog.show(
              context,
              failedChecks: error.failedChecks,
              onRetry: _retrySession,
            );
          }
        },
        builder: (context, state) {
          if (state is DeviceCheckRequired) {
            return TestMicAndSoundScreen(
              recorder: getIt<AudioRecorderService>(),
              player: DeviceCheckAudioPlayerImpl(),
              onComplete: () => context.read<ExamAttemptBloc>().add(
                SessionResolutionRequested(
                  rawInput: state.sessionPublicId,
                  deviceCheckConfirmed: true,
                ),
              ),
            );
          }
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
              audioPromptRepository: getIt<AudioPromptRepository>(),
            );
          }
          if (state is AttemptCompleted) {
            if (!_reportRevealed) {
              return SectionCompletedScreen(
                timeExpired: state.timeExpired,
                attemptNumber: state.attemptNumber,
                remainingRetries: state.remainingRetries,
                canRetry: state.canRetry,
                onContinue: () => setState(() => _reportRevealed = true),
                onRetry: () {
                  _reportRevealed = false;
                  _retrySession();
                },
              );
            }
            return ReportScreen(
              attemptPublicId: state.attemptPublicId,
              repository: getIt<ReportRepository>(),
              onBack: _resetToLogin,
            );
          }
          if (state is AttemptError) {
            return _AttemptStartErrorView(
              title: _attemptStarted
                  ? ExamAttemptStrings.attemptContinueFailureTitle
                  : ExamAttemptStrings.attemptStartFailureTitle,
              message: examAttemptFriendlyErrorMessage(state.error),
              onRetry: _retrySession,
              onChangeSession: _attemptStarted ? null : _resetToLogin,
            );
          }
          // AppAuthGate only constructs this widget after a student supplies
          // a session ID; there is no second session-entry screen.
          return const Scaffold(body: LoadingView());
        },
      ),
    );
  }
}

class _AttemptStartErrorView extends StatelessWidget {
  const _AttemptStartErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onChangeSession,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onChangeSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: AppDimensions.statusBannerIconSize,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    PrimaryButton(
                      label: ExamAttemptStrings.attemptStartRetry,
                      onPressed: onRetry,
                    ),
                    if (onChangeSession != null) ...[
                      const SizedBox(height: AppDimensions.spacingSm),
                      OutlinedButton(
                        onPressed: onChangeSession,
                        child: const Text(
                          ExamAttemptStrings.attemptStartChangeSession,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
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
            leading: const Icon(Icons.design_services),
            title: const Text('Complete exam UI catalog'),
            subtitle: const Text(
              'Review all 23 task screens without API or device side effects',
            ),
            onTap: () =>
                Navigator.of(context).pushNamed('/dev/standalone/exam-ui'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('PTE API mock exam'),
            subtitle: const Text(
              'Fetch two Repeat Sentence tasks from the dev-only API mock',
            ),
            onTap: () => Navigator.of(
              context,
            ).pushNamed('/dev/standalone/api-mock-exam'),
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
