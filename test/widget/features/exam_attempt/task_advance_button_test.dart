import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _FakeFlushableAnswerCubit implements FlushableAnswerCubit {
  final List<String> calls = [];

  @override
  Future<void> flushPendingEdit() async {
    calls.add('flushPendingEdit');
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const NextTaskRequested());
  });

  late _MockExamAttemptBloc bloc;
  late _MockSyncEngine syncEngine;
  late _FakeFlushableAnswerCubit cubit;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    syncEngine = _MockSyncEngine();
    cubit = _FakeFlushableAnswerCubit();
    when(() => syncEngine.flushOne(any())).thenAnswer((_) async {});
    // TaskAdvanceButton wraps itself in a BlocListener (auto-advance on
    // timer expiry), which reads bloc.state on mount — give the mock a
    // real initial state so that read doesn't throw. AttemptIdle rather
    // than AttemptInProgress: these tests exercise the manual tap path
    // only, and must never trigger the auto-expiry listener themselves.
    whenListen(bloc, const Stream<ExamAttemptState>.empty(), initialState: const AttemptIdle());
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: Scaffold(
          body: TaskAdvanceButton(cubit: cubit, pinnedItemPublicId: 'item-1', syncEngine: syncEngine),
        ),
      ),
    );
  }

  group('TaskAdvanceButton — flush-before-navigate ordering (Steps 4, 12)', () {
    testWidgets('tapping calls flushPendingEdit, then syncEngine.flushOne, then NextTaskRequested — in that order', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      // Note: not pumpAndSettle — the button shows an indefinitely
      // spinning CircularProgressIndicator once `_isAdvancing` is true
      // (production code never resets it, expecting the widget to be
      // navigated away instead), so pumpAndSettle would time out waiting
      // for that animation to finish. `tester.tap` itself awaits its
      // built-in pump, and the awaited Futures in `_advance()` are
      // already-resolved mocked Futures, so microtasks drain without
      // needing any additional real-time wait (`pumpEventQueue` must NOT
      // be used here — it relies on real `Timer`s, which never fire under
      // `testWidgets`'s fake-async zone, and hangs indefinitely).
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(cubit.calls, ['flushPendingEdit']);
      verify(() => syncEngine.flushOne('item-1')).called(1);
      verify(() => bloc.add(const NextTaskRequested())).called(1);
    });

    testWidgets('syncEngine.flushOne is called exactly once per tap, not per rebuild', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(() => syncEngine.flushOne('item-1')).called(1);
    });

    testWidgets('a second rapid tap while advancing is ignored (double-tap guard)', (tester) async {
      final completer = Completer<void>();
      when(() => syncEngine.flushOne(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      // Button is now mid-advance (disabled) — a second tap should be a
      // no-op since onPressed is null while _isAdvancing is true.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      completer.complete();
      await tester.pump();
      await tester.pump();

      expect(cubit.calls, ['flushPendingEdit']);
      verify(() => syncEngine.flushOne('item-1')).called(1);
      verify(() => bloc.add(const NextTaskRequested())).called(1);
    });
  });

  group('TaskAdvanceButton — auto-advance on timer expiry (Screen 7 Trigger 1)', () {
    TaskView task() {
      return TaskView(
        pinnedItemPublicId: 'item-1',
        orderIndex: 1,
        totalTasks: 5,
        section: 'READING',
        taskType: 'MC_READING_SINGLE',
        title: 'Task title',
        prepSeconds: 0,
        responseSeconds: 60,
      );
    }

    const runningSnapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 5), currentOrderIndex: 1);
    const expiredSnapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration.zero, currentOrderIndex: 1);

    late StreamController<ExamAttemptState> stateController;

    setUp(() {
      stateController = StreamController<ExamAttemptState>.broadcast();
      whenListen(
        bloc,
        stateController.stream,
        initialState: AttemptInProgress('attempt-1', task(), runningSnapshot),
      );
    });

    tearDown(() async {
      await stateController.close();
    });

    testWidgets('remaining hits zero (phase: response) auto-fires the same advance sequence, tagged timeExpired', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      stateController.add(AttemptInProgress('attempt-1', task(), expiredSnapshot));
      await tester.pump();

      expect(cubit.calls, ['flushPendingEdit']);
      verify(() => syncEngine.flushOne('item-1')).called(1);
      verify(() => bloc.add(const NextTaskRequested(reason: AdvanceReason.timeExpired))).called(1);
    });

    testWidgets('a second state update that is still expired does not re-fire the auto-advance', (tester) async {
      await tester.pumpWidget(buildSubject());

      stateController.add(AttemptInProgress('attempt-1', task(), expiredSnapshot));
      await tester.pump();
      // e.g. an unrelated rebuild while the fetch triggered above is still
      // in flight — the old task's AttemptInProgress/expiredSnapshot is
      // still what's displayed.
      stateController.add(AttemptInProgress('attempt-1', task(), expiredSnapshot));
      await tester.pump();

      verify(() => bloc.add(const NextTaskRequested(reason: AdvanceReason.timeExpired))).called(1);
    });

    testWidgets('remaining above zero never triggers the auto-advance', (tester) async {
      await tester.pumpWidget(buildSubject());

      stateController.add(
        AttemptInProgress(
          'attempt-1',
          task(),
          const TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 1), currentOrderIndex: 1),
        ),
      );
      await tester.pump();

      verifyNever(() => bloc.add(any()));
    });
  });
}
