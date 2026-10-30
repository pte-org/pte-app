import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAutoRecordCubit extends MockCubit<AutoRecordState>
    implements AutoRecordCubit {}

class _MockAudioPromptCubit extends MockCubit<AudioPromptPlaybackState>
    implements AudioPromptCubit {}

TaskView _task() {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 32,
    section: 'SPEAKING',
    taskType: 'REPEAT_SENTENCE',
    title: 'Repeat sentence',
    prepSeconds: 12,
    responseSeconds: 15,
  );
}

void main() {
  late _MockExamAttemptBloc examBloc;
  late _MockAutoRecordCubit autoRecordCubit;
  late _MockAudioPromptCubit audioPromptCubit;
  late StreamController<ExamAttemptState> examStateController;

  setUp(() {
    examBloc = _MockExamAttemptBloc();
    autoRecordCubit = _MockAutoRecordCubit();
    audioPromptCubit = _MockAudioPromptCubit();
    examStateController = StreamController<ExamAttemptState>.broadcast();
    when(
      () => autoRecordCubit.inputLevels,
    ).thenAnswer((_) => const Stream<double>.empty());
  });

  tearDown(() => examStateController.close());

  void stubExamState(TimerSnapshot snapshot) {
    final task = _task();
    final state = AttemptInProgress('attempt-1', task, snapshot);
    when(() => examBloc.state).thenReturn(state);
    whenListen(examBloc, examStateController.stream, initialState: state);
  }

  void stubPanelStates({
    required AudioPromptPlaybackState playback,
    Stream<AudioPromptPlaybackState>? playbackStream,
    AutoRecordState recording = const AutoRecordState(),
  }) {
    when(() => audioPromptCubit.state).thenReturn(playback);
    whenListen(
      audioPromptCubit,
      playbackStream ?? const Stream<AudioPromptPlaybackState>.empty(),
      initialState: playback,
    );
    when(() => autoRecordCubit.state).thenReturn(recording);
    whenListen(
      autoRecordCubit,
      const Stream<AutoRecordState>.empty(),
      initialState: recording,
    );
  }

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: examBloc,
        child: BlocProvider<AutoRecordCubit>.value(
          value: autoRecordCubit,
          child: BlocProvider<AudioPromptCubit>.value(
            value: audioPromptCubit,
            child: Scaffold(
              body: AudioPromptRecordBody(
                task: _task(),
                preListenSeconds: 3,
                preRecordSeconds: 3,
                instructionText: 'Repeat the sentence.',
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows only the player before the prompt is complete', (
    tester,
  ) async {
    stubExamState(
      const TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 7),
        currentOrderIndex: 1,
      ),
    );
    stubPanelStates(
      playback: const AudioPromptPlaybackState(
        phase: AudioPromptPlaybackPhase.playing,
        progress: 0.42,
      ),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
    expect(find.text('Audio Player'), findsOneWidget);
    expect(find.text('Audio Recorder'), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.42,
    );
  });

  testWidgets(
    'switches the same panel to the recorder when playback completes',
    (tester) async {
      stubExamState(
        const TimerSnapshot(
          phase: TimerPhase.prep,
          remaining: Duration(seconds: 7),
          currentOrderIndex: 1,
        ),
      );
      stubPanelStates(
        playback: const AudioPromptPlaybackState(
          phase: AudioPromptPlaybackPhase.completed,
          progress: 1.0,
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
      expect(find.text('Audio Player'), findsNothing);
      expect(find.text('Audio Recorder'), findsOneWidget);
      expect(find.text('Beginning in 7 seconds'), findsOneWidget);
    },
  );

  testWidgets('updates the same panel when playback completes while mounted', (
    tester,
  ) async {
    final playbackController =
        StreamController<AudioPromptPlaybackState>.broadcast();
    addTearDown(playbackController.close);

    stubExamState(
      const TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 7),
        currentOrderIndex: 1,
      ),
    );
    stubPanelStates(
      playback: const AudioPromptPlaybackState(
        phase: AudioPromptPlaybackPhase.playing,
        progress: 0.75,
      ),
      playbackStream: playbackController.stream,
    );

    await tester.pumpWidget(buildSubject());
    expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
    expect(find.text('Audio Player'), findsOneWidget);
    expect(find.text('Audio Recorder'), findsNothing);

    playbackController.add(
      const AudioPromptPlaybackState(
        phase: AudioPromptPlaybackPhase.completed,
        progress: 1.0,
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
    expect(find.text('Audio Player'), findsNothing);
    expect(find.text('Audio Recorder'), findsOneWidget);
  });

  testWidgets('keeps one recorder panel throughout the response window', (
    tester,
  ) async {
    stubExamState(
      const TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 15),
        currentOrderIndex: 1,
      ),
    );
    stubPanelStates(
      playback: const AudioPromptPlaybackState(
        phase: AudioPromptPlaybackPhase.playing,
        progress: 1.0,
      ),
      recording: const AutoRecordState(
        recordingPhase: RecordingPhase.recording,
      ),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
    expect(find.text('Audio Player'), findsNothing);
    expect(find.text('Audio Recorder'), findsOneWidget);
    expect(find.text('Recording 15 seconds left'), findsOneWidget);
  });
}
