import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_status_card.dart';

TaskView _task() {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 32,
    section: 'SPEAKING',
    taskType: 'READ_ALOUD',
    title: 'Read aloud',
    prepSeconds: 35,
    responseSeconds: 40,
  );
}

void main() {
  Widget buildSubject({
    required AutoRecordState recordingState,
    required TimerSnapshot? snapshot,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AutoRecordStatusCard(
          task: _task(),
          recordingState: recordingState,
          snapshot: snapshot,
        ),
      ),
    );
  }

  testWidgets(
    'prep phase shows a live "Beginning in…" countdown with progress forced to 0.0',
    (tester) async {
      const snapshot = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 10),
        currentOrderIndex: 1,
      );

      await tester.pumpWidget(
        buildSubject(
          recordingState: const AutoRecordState(),
          snapshot: snapshot,
        ),
      );

      expect(find.text('Beginning in 10 seconds'), findsOneWidget);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 0.0);
    },
  );

  testWidgets(
    'response phase shows the live "Recording… seconds left" label with the correct elapsed fraction',
    (tester) async {
      const snapshot = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 30),
        currentOrderIndex: 1,
      );

      await tester.pumpWidget(
        buildSubject(
          recordingState: const AutoRecordState(
            recordingPhase: RecordingPhase.recording,
          ),
          snapshot: snapshot,
        ),
      );

      expect(find.text('Recording 30 seconds left'), findsOneWidget);
      // task.responseSeconds = 40, remaining = 30 -> elapsed 10/40 = 0.25.
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 0.25);
    },
  );

  testWidgets(
    'recorded phase always wins regardless of the live snapshot phase, progress 1.0',
    (tester) async {
      const snapshot = TimerSnapshot(
        phase: TimerPhase.response,
        remaining: Duration(seconds: 5),
        currentOrderIndex: 1,
      );

      await tester.pumpWidget(
        buildSubject(
          recordingState: const AutoRecordState(
            recordingPhase: RecordingPhase.recorded,
          ),
          snapshot: snapshot,
        ),
      );

      expect(find.text('Still uploading…'), findsOneWidget);
      expect(find.textContaining('seconds left'), findsNothing);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0);
    },
  );

  testWidgets('unavailable microphone shows an actionable status', (
    tester,
  ) async {
    const snapshot = TimerSnapshot(
      phase: TimerPhase.response,
      remaining: Duration(seconds: 5),
      currentOrderIndex: 1,
    );

    await tester.pumpWidget(
      buildSubject(
        recordingState: const AutoRecordState(
          recordingPhase: RecordingPhase.unavailable,
        ),
        snapshot: snapshot,
      ),
    );

    expect(
      find.text('Microphone unavailable. Connect one before continuing.'),
      findsOneWidget,
    );
    expect(find.textContaining('seconds left'), findsNothing);
  });
}
