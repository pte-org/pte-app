import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/app.dart';
import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/violation_retry_coordinator.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/exam_attempt/dev/api_mock_exam_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/dev/listening_task_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/reading_task_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/speaking_writing_task_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}
class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}
class _MockSyncEngine extends Mock implements SyncEngine {}
class _MockAudioRecorderService extends Mock implements AudioRecorderService {}
class _MockPendingMediaUploadDao extends Mock implements PendingMediaUploadDao {}
class _MockMediaUploadCoordinator extends Mock implements MediaUploadCoordinator {}
class _MockAudioPlayerService extends Mock implements AudioPlayerService {}
class _MockAudioPromptRepository extends Mock implements AudioPromptRepository {}
class _MockExamAttemptRepository extends Mock implements ExamAttemptRepository {}
class _MockLockdownService extends Mock implements LockdownService {}

void main() {
  late _MockAudioPlayerService audioPlayer;
  late _MockAudioRecorderService audioRecorder;
  late _MockExamAttemptRepository examRepo;

  setUp(() {
    final getIt = GetIt.instance;
    final authBloc = _MockAuthBloc();
    final examBloc = _MockExamAttemptBloc();
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: const AuthIdle());
    whenListen(examBloc, const Stream<ExamAttemptState>.empty(), initialState: const AttemptIdle());

    final lockdown = _MockLockdownService();
    when(() => lockdown.enterDeviceCheckFullscreen()).thenAnswer((_) async {});
    when(() => lockdown.exitDeviceCheckFullscreen()).thenAnswer((_) async {});

    audioPlayer = _MockAudioPlayerService();
    when(() => audioPlayer.hasFinishedPlaying).thenAnswer((_) => const Stream<bool>.empty());
    when(() => audioPlayer.close()).thenAnswer((_) async {});

    audioRecorder = _MockAudioRecorderService();
    when(() => audioRecorder.inputLevels).thenAnswer((_) => const Stream<double>.empty());

    examRepo = _MockExamAttemptRepository();
    when(() => examRepo.startOrResumeAttempt(any())).thenThrow(Exception('mock load error'));

    getIt.registerSingleton<AuthBloc>(authBloc);
    getIt.registerSingleton<ExamAttemptBloc>(examBloc);
    getIt.registerSingleton<AnswerOutboxDao>(_MockAnswerOutboxDao());
    getIt.registerSingleton<SyncEngine>(_MockSyncEngine());
    getIt.registerSingleton<AudioRecorderService>(audioRecorder);
    getIt.registerSingleton<PendingMediaUploadDao>(_MockPendingMediaUploadDao());
    getIt.registerSingleton<MediaUploadCoordinator>(_MockMediaUploadCoordinator());
    getIt.registerSingleton<AudioPlayerService>(audioPlayer);
    getIt.registerSingleton<AudioPromptRepository>(_MockAudioPromptRepository());
    getIt.registerSingleton<ExamAttemptRepository>(examRepo);
    getIt.registerSingleton<LockdownService>(lockdown);
    getIt.registerSingleton<VolumeService>(VolumeService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('PteApp dev preview route builders', () {
    testWidgets('navigates to /dev/exam-ui-preview', (tester) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      final navContext = tester.element(find.byType(Navigator));
      Navigator.of(navContext).pushNamed('/dev/exam-ui-preview');
      await tester.pumpAndSettle();

      expect(find.byType(ExamUiPreviewScreen), findsOneWidget);
    });

    testWidgets('navigates to /dev/reading-preview', (tester) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      final navContext = tester.element(find.byType(Navigator));
      Navigator.of(navContext).pushNamed('/dev/reading-preview');
      await tester.pumpAndSettle();

      expect(find.byType(ReadingTaskPreviewScreen), findsOneWidget);
    });

    testWidgets('navigates to /dev/listening-preview', (tester) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      final navContext = tester.element(find.byType(Navigator));
      Navigator.of(navContext).pushNamed('/dev/listening-preview');
      await tester.pumpAndSettle();

      expect(find.byType(ListeningTaskPreviewScreen), findsOneWidget);
    });

    testWidgets('navigates to /dev/speaking-writing-preview', (tester) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      final navContext = tester.element(find.byType(Navigator));
      Navigator.of(navContext).pushNamed('/dev/speaking-writing-preview');
      await tester.pumpAndSettle();

      expect(find.byType(SpeakingWritingTaskPreviewScreen), findsOneWidget);
    });

    testWidgets('navigates to /dev/api-mock-exam', (tester) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      final navContext = tester.element(find.byType(Navigator));
      Navigator.of(navContext).pushNamed('/dev/api-mock-exam');
      await tester.pumpAndSettle();

      expect(find.byType(ApiMockExamPreviewScreen), findsOneWidget);
    });

    testWidgets('navigates to /dev/device-check-preview', (tester) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      final navContext = tester.element(find.byType(Navigator));
      Navigator.of(navContext).pushNamed('/dev/device-check-preview');
      await tester.pump();

      expect(find.byType(PteApp), findsOneWidget);
    });
  });
}
