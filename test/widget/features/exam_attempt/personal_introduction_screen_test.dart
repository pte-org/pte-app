import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/personal_introduction_screen.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockPendingMediaUploadDao extends Mock
    implements PendingMediaUploadDao {}

class _MockMediaUploadCoordinator extends Mock
    implements MediaUploadCoordinator {}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// `PersonalIntroductionScreen` constructs its own `AutoRecordCubit`
/// internally using the real `resolveRecordingFilePath`, which calls
/// `path_provider` — no platform channel handler is registered in the
/// widget-test environment by default, so `getTemporaryDirectory()` throws
/// `MissingPluginException` unless this fake is installed. The path never
/// has to resolve to anything real since [_MockAudioRecorderService] never
/// touches the filesystem.
class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => '/tmp';
}

TaskView _personalIntroductionTask({String pinnedItemPublicId = 'item-1'}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 32,
    section: 'SPEAKING',
    taskType: 'PERSONAL_INTRODUCTION',
    title: 'Personal introduction',
    promptText:
        'Please introduce yourself. For example, you could talk about one or more of the following:\n\n'
        '• Your interests\n'
        '• Why you chose this test',
    prepSeconds: 25,
    responseSeconds: 30,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 25),
    responseDeadline: DateTime(2026, 1, 1, 0, 0, 55),
    serverNow: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  late _MockExamAttemptBloc bloc;
  late _MockAudioRecorderService recorder;
  late _MockPendingMediaUploadDao mediaDao;
  late _MockMediaUploadCoordinator coordinator;
  late _MockSyncEngine syncEngine;
  late StreamController<ExamAttemptState> stateController;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    recorder = _MockAudioRecorderService();
    mediaDao = _MockPendingMediaUploadDao();
    coordinator = _MockMediaUploadCoordinator();
    syncEngine = _MockSyncEngine();
    stateController = StreamController<ExamAttemptState>.broadcast();

    when(
      () => mediaDao.watchRow(any(), any()),
    ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
    when(() => recorder.start(any())).thenAnswer((_) async {});
    when(() => recorder.stop()).thenAnswer((_) async => null);
  });

  tearDown(() => stateController.close());

  Widget buildSubject({TaskView? task}) {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: PersonalIntroductionScreen(
          task: task ?? _personalIntroductionTask(),
          attemptPublicId: 'attempt-1',
          recorder: recorder,
          mediaDao: mediaDao,
          coordinator: coordinator,
          syncEngine: syncEngine,
        ),
      ),
    );
  }

  void stubBlocState(ExamAttemptState initial) {
    when(() => bloc.state).thenReturn(initial);
    whenListen(bloc, stateController.stream, initialState: initial);
  }

  testWidgets(
    'renders the instruction text interpolating prepSeconds (25) then responseSeconds (30) — not the same '
    'value twice',
    (tester) async {
      const snapshot = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 25),
        currentOrderIndex: 1,
      );
      stubBlocState(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), snapshot),
      );

      await tester.pumpWidget(buildSubject());

      expect(
        find.text(
          'Read the prompt below. In 25 seconds, you must reply in your own words, as naturally and clearly as '
          'possible. You have 30 seconds to record your response.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders the bulleted prompt text', (tester) async {
    const snapshot = TimerSnapshot(
      phase: TimerPhase.prep,
      remaining: Duration(seconds: 25),
      currentOrderIndex: 1,
    );
    stubBlocState(
      AttemptInProgress('attempt-1', _personalIntroductionTask(), snapshot),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.textContaining('Please introduce yourself.'), findsOneWidget);
    expect(find.textContaining('Your interests'), findsOneWidget);
  });

  testWidgets(
    'prep phase shows a live "Beginning in…" countdown card, and never starts recording',
    (tester) async {
      const snapshot = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 10),
        currentOrderIndex: 1,
      );
      stubBlocState(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), snapshot),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Beginning in 10 seconds'), findsOneWidget);
      verifyNever(() => recorder.start(any()));
    },
  );

  testWidgets(
    'a new response-phase snapshot on the bloc stream auto-starts recording and shows the "Recording" card',
    (tester) async {
      const prep = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 1),
        currentOrderIndex: 1,
      );
      stubBlocState(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), prep),
      );

      await tester.pumpWidget(buildSubject());
      expect(find.text('Beginning in 1 seconds'), findsOneWidget);

      const response = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 30),
        currentOrderIndex: 1,
      );
      stateController.add(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), response),
      );
      await tester.pump();
      await tester.pump();

      verify(() => recorder.start(any())).called(1);
      expect(find.text('Recording 30 seconds left'), findsOneWidget);
    },
  );

  testWidgets(
    'full prep -> response -> recorded transition: once the response countdown reaches zero the recorder '
    'stops and the upload-status card replaces the "Recording" card',
    (tester) async {
      when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav');
      when(
        () => mediaDao.upsertRecorded(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          localFilePath: any(named: 'localFilePath'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => coordinator.attemptUpload(any(), any()),
      ).thenAnswer((_) async {});

      const prep = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 1),
        currentOrderIndex: 1,
      );
      stubBlocState(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), prep),
      );

      await tester.pumpWidget(buildSubject());

      const response = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 30),
        currentOrderIndex: 1,
      );
      stateController.add(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), response),
      );
      await tester.pump();
      await tester.pump();
      verify(() => recorder.start(any())).called(1);

      const expired = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration.zero,
        currentOrderIndex: 1,
      );
      stateController.add(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), expired),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      verify(() => recorder.stop()).called(1);
      // Recorded phase always wins over the live timer phase — the
      // "Recording" card must be gone, replaced by the upload-status card
      // (uploadStatus stays null in this test since watchRow's stream is
      // empty, so it falls back to the "still uploading" label). Only the
      // status card renders this text now — AutoAdvanceOnUploadReady renders
      // nothing, unlike a manual "Next" button (deliberately not built here).
      expect(find.text('Still uploading…'), findsOneWidget);
      expect(find.textContaining('seconds left'), findsNothing);
    },
  );

  testWidgets(
    'a snapshot for a different task (pinnedItemPublicId mismatch) is never forwarded — recorder.start is never '
    'called for it',
    (tester) async {
      const prep = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 1),
        currentOrderIndex: 1,
      );
      stubBlocState(
        AttemptInProgress('attempt-1', _personalIntroductionTask(), prep),
      );

      await tester.pumpWidget(buildSubject());

      const otherTaskResponse = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 30),
        currentOrderIndex: 2,
      );
      stateController.add(
        AttemptInProgress(
          'attempt-1',
          _personalIntroductionTask(pinnedItemPublicId: 'item-2'),
          otherTaskResponse,
        ),
      );
      await tester.pump();
      await tester.pump();

      verifyNever(() => recorder.start(any()));
    },
  );
}
