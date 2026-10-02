import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_navigation_direction.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _FakeFlushableAnswerCubit implements FlushableAnswerCubit {
  final List<String> calls = [];

  @override
  bool get hasPendingEdits => true;

  @override
  Future<void> flushPendingEdit() async => calls.add('flushPendingEdit');
}

TaskView sampleTask({
  String pinnedItemPublicId = 'item-1',
  bool canNavigatePrevious = true,
  bool canNavigateNext = true,
}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: 0,
    responseSeconds: 60,
    canNavigatePrevious: canNavigatePrevious,
    canNavigateNext: canNavigateNext,
  );
}

const _runningSnapshot = TimerSnapshot(
  phase: TimerPhase.response,
  remaining: Duration(seconds: 5),
  currentOrderIndex: 1,
);
const _expiredSnapshot = TimerSnapshot(
  phase: TimerPhase.response,
  remaining: Duration.zero,
  currentOrderIndex: 1,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NextTaskRequested());
    registerFallbackValue(
      const NavigateTaskRequested(
        fromPinnedItemPublicId: 'item-fallback',
        direction: TaskNavigationDirection.next,
      ),
    );
  });

  late _MockExamAttemptBloc bloc;
  late _MockSyncEngine syncEngine;
  late _FakeFlushableAnswerCubit cubit;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    syncEngine = _MockSyncEngine();
    cubit = _FakeFlushableAnswerCubit();
    when(
      () => syncEngine.flushOne(any(), advance: any(named: 'advance')),
    ).thenAnswer((_) async {});
    whenListen(
      bloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: AttemptInProgress(
        'attempt-1',
        sampleTask(),
        _runningSnapshot,
      ),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: Scaffold(
          body: TaskAdvanceButton(
            cubit: cubit,
            pinnedItemPublicId: 'item-1',
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }

  group('manual Previous/Next', () {
    testWidgets('Next saves without advancing, then requests navigation', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(cubit.calls, ['flushPendingEdit']);
      verify(() => syncEngine.flushOne('item-1', advance: false)).called(1);
      verify(
        () => bloc.add(
          const NavigateTaskRequested(
            fromPinnedItemPublicId: 'item-1',
            direction: TaskNavigationDirection.next,
          ),
        ),
      ).called(1);
    });

    testWidgets('Previous requests the previous task', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.widgetWithText(OutlinedButton, 'Previous'));
      await tester.pump();

      verify(
        () => bloc.add(
          const NavigateTaskRequested(
            fromPinnedItemPublicId: 'item-1',
            direction: TaskNavigationDirection.previous,
          ),
        ),
      ).called(1);
    });

    testWidgets('navigation loading ends after the next task is received', (
      tester,
    ) async {
      final controller = StreamController<ExamAttemptState>.broadcast();
      whenListen(
        bloc,
        controller.stream,
        initialState: AttemptInProgress(
          'attempt-1',
          sampleTask(),
          _runningSnapshot,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      controller.add(
        AttemptInProgress(
          'attempt-1',
          sampleTask(pinnedItemPublicId: 'item-2'),
          _runningSnapshot,
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(() => bloc.add(any(that: isA<NavigateTaskRequested>()))).called(2);
      await controller.close();
    });

    testWidgets('rapid repeat taps are ignored while save is pending', (
      tester,
    ) async {
      final completer = Completer<void>();
      when(
        () => syncEngine.flushOne(any(), advance: any(named: 'advance')),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      completer.complete();
      await tester.pump();
      await tester.pump();

      verify(() => syncEngine.flushOne('item-1', advance: false)).called(1);
      verify(() => bloc.add(any(that: isA<NavigateTaskRequested>()))).called(1);
    });
  });

  testWidgets('response timer expiry retains submit-and-advance behavior', (
    tester,
  ) async {
    final controller = StreamController<ExamAttemptState>.broadcast();
    whenListen(
      bloc,
      controller.stream,
      initialState: AttemptInProgress(
        'attempt-1',
        sampleTask(),
        _runningSnapshot,
      ),
    );

    await tester.pumpWidget(buildSubject());
    controller.add(
      AttemptInProgress('attempt-1', sampleTask(), _expiredSnapshot),
    );
    await tester.pump();

    expect(cubit.calls, ['flushPendingEdit']);
    verify(() => syncEngine.flushOne('item-1')).called(1);
    verify(
      () =>
          bloc.add(const NextTaskRequested(reason: AdvanceReason.timeExpired)),
    ).called(1);
    await controller.close();
  });
}
