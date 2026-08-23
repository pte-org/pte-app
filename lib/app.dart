import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_dimensions.dart';
import 'core/constants/app_strings.dart';
import 'core/storage/dao/answer_outbox_dao.dart';
import 'core/storage/dao/pending_media_upload_dao.dart';
import 'core/sync/media_upload_coordinator.dart';
import 'core/sync/sync_engine.dart';
import 'core/widgets/loading_view.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/exam_attempt/listening/dev/listening_task_preview_screen.dart';
import 'features/exam_attempt/listening/domain/audio_player_service.dart';
import 'features/exam_attempt/reading/dev/reading_task_preview_screen.dart';
import 'features/exam_attempt/speaking_writing/dev/speaking_writing_task_preview_screen.dart';
import 'features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'features/host_console/domain/host_access_policy.dart';
import 'features/host_console/presentation/pages/host_console_page.dart';
import 'features/live_proctor/domain/live_proctor_access_policy.dart';
import 'features/live_proctor/presentation/pages/proctor_workspace_page.dart';

class PteApp extends StatelessWidget {
  const PteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
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
            AuthAuthenticated() => _StudentWorkspaceWithDevFab(),
          };
        },
      ),
    );
  }
}

/// Wraps the student placeholder with a debug-only FAB column for the three
/// dev preview screens. Hidden in release builds.
class _StudentWorkspaceWithDevFab extends StatelessWidget {
  const _StudentWorkspaceWithDevFab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text(AppStrings.studentWorkspacePlaceholder)),
      floatingActionButton: kDebugMode
          ? _DevFabColumn(onNavigate: (route) => Navigator.of(context).pushNamed(route))
          : null,
    );
  }
}

class _DevFabColumn extends StatelessWidget {
  const _DevFabColumn({required this.onNavigate});

  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'dev-reading-preview',
          onPressed: () => onNavigate('/dev/reading-preview'),
          child: const Icon(Icons.menu_book),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        FloatingActionButton(
          heroTag: 'dev-listening-preview',
          onPressed: () => onNavigate('/dev/listening-preview'),
          child: const Icon(Icons.headphones),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        FloatingActionButton(
          heroTag: 'dev-speaking-writing-preview',
          onPressed: () => onNavigate('/dev/speaking-writing-preview'),
          child: const Icon(Icons.mic),
        ),
      ],
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
            onTap: () => Navigator.of(context)
                .pushNamed('/dev/standalone/speaking-writing'),
          ),
        ],
      ),
    );
  }
}
