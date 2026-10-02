import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_drag_drop_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_drag_drop_body.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

TaskView _task() {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 0,
    totalTasks: 5,
    section: 'READING',
    taskType: 'FILL_IN_THE_BLANKS_DRAG_AND_DROP',
    title: 'title',
    promptText: 'A {{0}} start.',
    options: const [TaskOption(text: 'quick', orderIndex: '0'), TaskOption(text: 'slow', orderIndex: '1')],
    prepSeconds: 0,
    responseSeconds: 60,
  );
}

void main() {
  late _MockAnswerOutboxDao outboxDao;
  late FillBlanksDragDropCubit cubit;

  setUp(() {
    outboxDao = _MockAnswerOutboxDao();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    cubit = FillBlanksDragDropCubit(
      outboxDao: outboxDao,
      attemptPublicId: 'attempt-1',
      pinnedItemPublicId: 'item-1',
      gapCount: 1,
    );
  });

  tearDown(() => cubit.close());

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<FillBlanksDragDropCubit>.value(value: cubit, child: FillBlanksDragDropBody(task: _task())),
      ),
    );
  }

  testWidgets('renders the gap placeholder and both bank chips before any drag', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('_____'), findsOneWidget);
    expect(find.text('quick'), findsOneWidget);
    expect(find.text('slow'), findsOneWidget);
  });

  testWidgets('dragging a bank chip into the gap fills it and removes the chip from the bank', (tester) async {
    await tester.pumpWidget(buildSubject());

    final chipCenter = tester.getCenter(find.text('quick'));
    final gapCenter = tester.getCenter(find.text('_____'));

    final gesture = await tester.startGesture(chipCenter);
    await tester.pump();
    await gesture.moveTo(gapCenter);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(cubit.state.gapAssignments, {0: const TaskOption(text: 'quick', orderIndex: '0')});
    expect(find.text('_____'), findsNothing);
    // "quick" now renders once, inside the gap — not also still in the bank.
    expect(find.text('quick'), findsOneWidget);
  });

  testWidgets('dragging a filled gap word back onto the bank clears the gap and restores the chip', (tester) async {
    await cubit.assignToGap(0, const TaskOption(text: 'quick', orderIndex: '0'));
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final gapWordCenter = tester.getCenter(find.text('quick'));
    final bankAreaCenter = tester.getCenter(find.text('slow'));

    final gesture = await tester.startGesture(gapWordCenter);
    await tester.pump();
    await gesture.moveTo(bankAreaCenter);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(cubit.state.gapAssignments, isEmpty);
    expect(find.text('_____'), findsOneWidget);
    expect(find.text('quick'), findsOneWidget);
    expect(find.text('slow'), findsOneWidget);
  });

  testWidgets('word-bank chip order is stable across a place/undo cycle (Step 10)', (tester) async {
    await tester.pumpWidget(buildSubject());

    // Initial bank order: quick, then slow.
    final initialOrder = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(initialOrder.indexOf('quick') < initialOrder.indexOf('slow'), isTrue);

    await cubit.assignToGap(0, const TaskOption(text: 'quick', orderIndex: '0'));
    await tester.pump();
    await cubit.clearGap(0);
    await tester.pump();

    final afterUndoOrder = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    // "quick" must reappear before "slow" — matching task.options' original
    // order, not appended to the end after being placed/undone.
    expect(afterUndoOrder.indexOf('quick') < afterUndoOrder.indexOf('slow'), isTrue);
  });

  testWidgets('gap highlights while a compatible chip is dragged over it, per DragTarget candidateData', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    Color? decorationColor() {
      final container = tester.widget<Container>(
        find.ancestor(of: find.text('_____'), matching: find.byType(Container)).first,
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    expect(decorationColor(), isNot(AppColors.dragTargetHoverBackground));

    final chipCenter = tester.getCenter(find.text('quick'));
    final gapCenter = tester.getCenter(find.text('_____'));
    final gesture = await tester.startGesture(chipCenter);
    await tester.pump();
    await gesture.moveTo(gapCenter);
    await tester.pump();

    expect(decorationColor(), AppColors.dragTargetHoverBackground);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
