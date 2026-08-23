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
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/answer_short_question_screen.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockPendingMediaUploadDao extends Mock
    implements PendingMediaUploadDao {}

class _MockMediaUploadCoordinator extends Mock
    implements MediaUploadCoordinator {}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// `AnswerShortQuestionScreen` constructs its own `AutoRecordCubit`
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

/// Fixture matches the app's own dev fixture: `prepSeconds: 14` is the sum
/// of the 3 mocked sub-stages (3s pre-listen + 8s audio + 3s pre-record),
/// `responseSeconds: 10` is the recording window.
TaskView _answerShortQuestionTask({String pinnedItemPublicId = 'item-1'}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 32,
    section: 'SPEAKING',
    taskType: 'ANSWER_SHORT_QUESTION',
    title: 'Answer short question',
    prepSeconds: 14,
    responseSeconds: 10,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 14),
    responseDeadline: DateTime(2026, 1, 1, 0, 0, 24),
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
        child: AnswerShortQuestionScreen(
          task: task ?? _answerShortQuestionTask(),
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

  testWidgets('renders the fixed instruction text (no interpolated variables)', (
    tester,
  ) async {
    const snapshot = TimerSnapshot(
      phase: TimerPhase.prep,
      remaining: Duration(seconds: 14),
      currentOrderIndex: 1,
    );
    stubBlocState(
      AttemptInProgress('attempt-1', _answerShortQuestionTask(), snapshot),
    );

    await tester.pumpWidget(buildSubject());

    expect(
      find.text(
        'You will hear a question. Please give a simple and short answer. Often just once or a few words is '
        'enough.',
      ),
      findsOneWidget,
    );
  });

  group(
    'the two cards always render simultaneously, each on its own independent sub-stage countdown',
    () {
      testWidgets(
        'elapsed 0s (start of pre-listen prep): Listening shows "Beginning in 3", Record is blank',
        (tester) async {
          const snapshot = TimerSnapshot(
            phase: TimerPhase.prep,
            remaining: Duration(seconds: 14),
            currentOrderIndex: 1,
          );
          stubBlocState(
            AttemptInProgress(
              'attempt-1',
              _answerShortQuestionTask(),
              snapshot,
            ),
          );

          await tester.pumpWidget(buildSubject());

          expect(find.text('Beginning in 3 seconds'), findsOneWidget);
          expect(
            find.text('Volume'),
            findsOneWidget,
          ); // proves the Listening card rendered
          expect(
            find.text('Recorded Answer'),
            findsOneWidget,
          ); // the Record card is always present too
          verifyNever(() => recorder.start(any()));
        },
      );

      testWidgets(
        'elapsed 5s (mid audio playback): Listening shows "Playing 6 seconds left", Record still blank',
        (tester) async {
          // prepSeconds 14 - elapsed 5 = remaining 9.
          const snapshot = TimerSnapshot(
            phase: TimerPhase.prep,
            remaining: Duration(seconds: 9),
            currentOrderIndex: 1,
          );
          stubBlocState(
            AttemptInProgress(
              'attempt-1',
              _answerShortQuestionTask(),
              snapshot,
            ),
          );

          await tester.pumpWidget(buildSubject());

          expect(find.text('Playing 6 seconds left'), findsOneWidget);
          // The Record card's bold status Text is empty in this sub-stage — its
          // "Current Status:" label is still present (card always rendered),
          // but no "Beginning in…"/"Recording" text should exist yet.
          expect(find.textContaining('Beginning in'), findsNothing);
          verifyNever(() => recorder.start(any()));
        },
      );

      testWidgets(
        'elapsed 13s (mid pre-record prep, listening finished): Listening frozen at "Playing 0", Record shows '
        '"Beginning in 1"',
        (tester) async {
          // prepSeconds 14 - elapsed 13 = remaining 1.
          const snapshot = TimerSnapshot(
            phase: TimerPhase.prep,
            remaining: Duration(seconds: 1),
            currentOrderIndex: 1,
          );
          stubBlocState(
            AttemptInProgress(
              'attempt-1',
              _answerShortQuestionTask(),
              snapshot,
            ),
          );

          await tester.pumpWidget(buildSubject());

          expect(find.text('Playing 0 seconds left'), findsOneWidget);
          expect(find.text('Beginning in 1 seconds'), findsOneWidget);
          verifyNever(() => recorder.start(any()));
        },
      );
    },
  );

  testWidgets(
    'a new response-phase snapshot on the bloc stream auto-starts recording; Listening stays frozen, Record shows '
    '"Recording"',
    (tester) async {
      const prep = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 1),
        currentOrderIndex: 1,
      );
      stubBlocState(
        AttemptInProgress('attempt-1', _answerShortQuestionTask(), prep),
      );

      await tester.pumpWidget(buildSubject());
      expect(find.text('Beginning in 1 seconds'), findsOneWidget);

      const response = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 10),
        currentOrderIndex: 1,
      );
      stateController.add(
        AttemptInProgress('attempt-1', _answerShortQuestionTask(), response),
      );
      await tester.pump();
      await tester.pump();

      verify(() => recorder.start(any())).called(1);
      expect(find.text('Playing 0 seconds left'), findsOneWidget);
      expect(find.text('Recording 10 seconds left'), findsOneWidget);
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
        AttemptInProgress('attempt-1', _answerShortQuestionTask(), prep),
      );

      await tester.pumpWidget(buildSubject());

      const response = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 10),
        currentOrderIndex: 1,
      );
      stateController.add(
        AttemptInProgress('attempt-1', _answerShortQuestionTask(), response),
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
        AttemptInProgress('attempt-1', _answerShortQuestionTask(), expired),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      verify(() => recorder.stop()).called(1);
      // Recorded phase always wins over the live timer phase — the
      // "Recording" card must be gone, replaced by the upload-status card
      // (uploadStatus stays null in this test since watchRow's stream is
      // empty, so it falls back to the "still uploading" label). The
      // Listening card is unaffected by recording status — it stays frozen
      // at "Playing 0 seconds left" (elapsed == prepSeconds once response
      // is reached), which is expected, not a leftover recording label.
      expect(find.text('Still uploading…'), findsOneWidget);
      expect(find.text('Recording 10 seconds left'), findsNothing);
      expect(find.text('Playing 0 seconds left'), findsOneWidget);
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
        AttemptInProgress('attempt-1', _answerShortQuestionTask(), prep),
      );

      await tester.pumpWidget(buildSubject());

      const otherTaskResponse = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 10),
        currentOrderIndex: 2,
      );
      stateController.add(
        AttemptInProgress(
          'attempt-1',
          _answerShortQuestionTask(pinnedItemPublicId: 'item-2'),
          otherTaskResponse,
        ),
      );
      await tester.pump();
      await tester.pump();

      verifyNever(() => recorder.start(any()));
    },
  );
}
