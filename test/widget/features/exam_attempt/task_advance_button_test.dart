import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_navigation_constants.dart';
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
  String section = 'READING',
  int orderIndex = 1,
}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: orderIndex,
    totalTasks: 5,
    section: section,
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: 0,
    responseSeconds: 60,
    // The server flags are ignored by the forward-only button.
    canNavigatePrevious: true,
    canNavigateNext: true,
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

/// A two-task attempt positioned on the first task, so Next is shown.
AttemptInProgress firstOfTwo({
  String section = 'READING',
  TimerSnapshot snapshot = _runningSnapshot,
}) {
  final first = sampleTask(section: section);
  return AttemptInProgress(
    'attempt-1',
    first,
    snapshot,
    allTasks: [
      first,
      sampleTask(pinnedItemPublicId: 'item-2', section: section),
    ],
  );
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
    when(() => syncEngine.submitForAdvance(any())).thenAnswer((_) async {});
    whenListen(
      bloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: firstOfTwo(),
    );
  });

  Widget buildSubject({
    bool autoAdvanceOnExpiration = true,
    Future<void> Function()? beforeLeaving,
  }) {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: Scaffold(
          body: TaskAdvanceButton(
            cubit: cubit,
            pinnedItemPublicId: 'item-1',
            syncEngine: syncEngine,
            autoAdvanceOnExpiration: autoAdvanceOnExpiration,
            beforeLeaving: beforeLeaving,
          ),
        ),
      ),
    );
  }

  /// Lets the post-task-appears cooldown elapse so Next becomes tappable.
  Future<void> pastCooldown(WidgetTester tester) => tester.pump(
    ExamAttemptNavigationConstants.nextCooldown +
        const Duration(milliseconds: 50),
  );

  ElevatedButton nextButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  group('forward-only Next', () {
    testWidgets('never shows Previous', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsNothing);
    });

    testWidgets('is hidden on the last task', (tester) async {
      whenListen(
        bloc,
        const Stream<ExamAttemptState>.empty(),
        initialState: AttemptInProgress(
          'attempt-1',
          sampleTask(orderIndex: 4),
          _runningSnapshot,
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('is disabled during the cooldown, enabled after it', (
      tester,
    ) async {
      when(() => bloc.taskActivatedAt).thenReturn(DateTime.now());
      await tester.pumpWidget(buildSubject());
      expect(nextButton(tester).onPressed, isNull);

      await pastCooldown(tester);
      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets(
      'a tap flushes the edit, submits the task, then requests the next one',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await pastCooldown(tester);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();

        expect(cubit.calls, ['flushPendingEdit']);
        verify(() => syncEngine.submitForAdvance('item-1')).called(1);
        verify(
          () => bloc.add(
            const NextTaskRequested(
              fromPinnedItemPublicId: 'item-1',
              userInitiated: true,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'a tap from a screen whose task is no longer active does nothing',
      (tester) async {
        // The screen shows item-0 but the bloc already moved to item-1.
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ExamAttemptBloc>.value(
              value: bloc,
              child: Scaffold(
                body: TaskAdvanceButton(
                  cubit: cubit,
                  pinnedItemPublicId: 'item-0',
                  syncEngine: syncEngine,
                ),
              ),
            ),
          ),
        );
        await pastCooldown(tester);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();

        verifyNever(() => syncEngine.submitForAdvance(any()));
        verifyNever(() => bloc.add(any(that: isA<NextTaskRequested>())));
      },
    );

    testWidgets('a second tap while the submit is in flight is ignored', (
      tester,
    ) async {
      final completer = Completer<void>();
      when(
        () => syncEngine.submitForAdvance(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await pastCooldown(tester);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      completer.complete();
      await tester.pump();
      await tester.pump();

      verify(() => syncEngine.submitForAdvance('item-1')).called(1);
      verify(() => bloc.add(any(that: isA<NextTaskRequested>()))).called(1);
    });

    testWidgets(
      'stays locked after Next is dispatched until the settle timeout',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await pastCooldown(tester);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();
        verify(() => bloc.add(any(that: isA<NextTaskRequested>()))).called(1);

        // The bloc has not moved on (e.g. a slow task-list reload): a second tap
        // must not re-submit the task.
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();
        verify(() => syncEngine.submitForAdvance('item-1')).called(1);

        // If the bloc ignored the event the button is released after a while.
        await tester.pump(ExamAttemptNavigationConstants.advanceSettleTimeout);
        expect(nextButton(tester).onPressed, isNotNull);
      },
    );

    testWidgets('a new task restarts the cooldown', (tester) async {
      when(() => bloc.taskActivatedAt).thenReturn(null);
      final controller = StreamController<ExamAttemptState>.broadcast();
      whenListen(bloc, controller.stream, initialState: firstOfTwo());
      final tasks = [
        sampleTask(),
        sampleTask(pinnedItemPublicId: 'item-2'),
        sampleTask(pinnedItemPublicId: 'item-3'),
      ];

      await tester.pumpWidget(buildSubject());
      await pastCooldown(tester);
      expect(nextButton(tester).onPressed, isNotNull);

      controller.add(
        AttemptInProgress(
          'attempt-1',
          tasks[1],
          _runningSnapshot,
          allTasks: tasks,
          currentIndex: 1,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(nextButton(tester).onPressed, isNull);

      await pastCooldown(tester);
      expect(nextButton(tester).onPressed, isNotNull);
      await controller.close();
    });

    group('beforeLeaving hook', () {
      testWidgets('runs after the flush and before the submit, then advances', (
        tester,
      ) async {
        final order = <String>[];
        when(() => syncEngine.submitForAdvance(any())).thenAnswer((_) async {
          order.add('submit');
        });

        await tester.pumpWidget(
          buildSubject(
            beforeLeaving: () async {
              order.addAll(cubit.calls);
              order.add('hook');
            },
          ),
        );
        await pastCooldown(tester);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();

        expect(order, ['flushPendingEdit', 'hook', 'submit']);
        verify(() => bloc.add(any(that: isA<NextTaskRequested>()))).called(1);
      });

      testWidgets('a throwing hook never blocks Next', (tester) async {
        await tester.pumpWidget(
          buildSubject(beforeLeaving: () async => throw StateError('boom')),
        );
        await pastCooldown(tester);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();

        verify(() => syncEngine.submitForAdvance('item-1')).called(1);
        verify(() => bloc.add(any(that: isA<NextTaskRequested>()))).called(1);
      });

      testWidgets('a hanging hook is abandoned after the leave timeout', (
        tester,
      ) async {
        final never = Completer<void>();
        await tester.pumpWidget(
          buildSubject(beforeLeaving: () => never.future),
        );
        await pastCooldown(tester);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        verifyNever(() => syncEngine.submitForAdvance(any()));

        await tester.pump(ExamAttemptNavigationConstants.leaveHookTimeout);
        await tester.pump();
        await tester.pump();

        verify(() => syncEngine.submitForAdvance('item-1')).called(1);
        verify(() => bloc.add(any(that: isA<NextTaskRequested>()))).called(1);
      });
    });
  });

  // Official READING/WRITING never auto-advance on expiry, so this runs on a
  // LISTENING task. The timer path is not subject to the tap cooldown.
  testWidgets('response timer expiry submits and advances without a tap', (
    tester,
  ) async {
    final controller = StreamController<ExamAttemptState>.broadcast();
    whenListen(
      bloc,
      controller.stream,
      initialState: firstOfTwo(section: 'LISTENING'),
    );

    await tester.pumpWidget(buildSubject());
    controller.add(
      firstOfTwo(section: 'LISTENING', snapshot: _expiredSnapshot),
    );
    await tester.pump();
    await tester.pump();

    expect(cubit.calls, ['flushPendingEdit']);
    verify(() => syncEngine.submitForAdvance('item-1')).called(1);
    verify(
      () => bloc.add(
        const NextTaskRequested(
          reason: AdvanceReason.timeExpired,
          fromPinnedItemPublicId: 'item-1',
        ),
      ),
    ).called(1);
    await controller.close();
  });

  for (final section in ['READING', 'WRITING']) {
    testWidgets('$section: response timer expiry never auto-advances', (
      tester,
    ) async {
      final controller = StreamController<ExamAttemptState>.broadcast();
      whenListen(
        bloc,
        controller.stream,
        initialState: firstOfTwo(section: section),
      );

      await tester.pumpWidget(buildSubject());
      controller.add(firstOfTwo(section: section, snapshot: _expiredSnapshot));
      await tester.pump();

      expect(cubit.calls, isEmpty);
      verifyNever(() => syncEngine.submitForAdvance(any()));
      verifyNever(() => bloc.add(any(that: isA<NextTaskRequested>())));
      await controller.close();
    });
  }

  testWidgets(
    'LISTENING: autoAdvanceOnExpiration=false suppresses auto-advance on expiry',
    (tester) async {
      final controller = StreamController<ExamAttemptState>.broadcast();
      whenListen(
        bloc,
        controller.stream,
        initialState: firstOfTwo(section: 'LISTENING'),
      );

      await tester.pumpWidget(buildSubject(autoAdvanceOnExpiration: false));
      controller.add(
        firstOfTwo(section: 'LISTENING', snapshot: _expiredSnapshot),
      );
      await tester.pump();

      expect(cubit.calls, isEmpty);
      verifyNever(() => bloc.add(any(that: isA<NextTaskRequested>())));
      await controller.close();
    },
  );
}
