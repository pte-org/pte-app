import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_dropdown_body.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

TaskView _task() {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 0,
    totalTasks: 5,
    section: 'READING',
    taskType: 'FILL_BLANKS_READING_WRITING',
    title: 'title',
    promptText: 'It was {{0}} but {{1}}.',
    blankGroups: const [
      BlankGroup(blankIndex: 0, options: [TaskOption(text: 'sunny', orderIndex: '0'), TaskOption(text: 'rainy', orderIndex: '1')]),
      BlankGroup(blankIndex: 1, options: [TaskOption(text: 'cold', orderIndex: '0'), TaskOption(text: 'warm', orderIndex: '1')]),
    ],
    prepSeconds: 0,
    responseSeconds: 60,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: DateTime(2026, 1, 1),
  );
}

void main() {
  late _MockAnswerOutboxDao outboxDao;
  late FillBlanksDropdownCubit cubit;

  setUp(() {
    outboxDao = _MockAnswerOutboxDao();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    cubit = FillBlanksDropdownCubit(
      outboxDao: outboxDao,
      attemptPublicId: 'attempt-1',
      pinnedItemPublicId: 'item-1',
      blankGroupCount: 2,
    );
  });

  tearDown(() => cubit.close());

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<FillBlanksDropdownCubit>.value(value: cubit, child: FillBlanksDropdownBody(task: _task())),
      ),
    );
  }

  testWidgets('each gap renders as an independent DropdownButton with only its own gap\'s options', (tester) async {
    await tester.pumpWidget(buildSubject());

    final dropdowns = tester.widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>)).toList();
    expect(dropdowns, hasLength(2));

    final gap0Values = dropdowns[0].items!.map((item) => item.value).toSet();
    final gap1Values = dropdowns[1].items!.map((item) => item.value).toSet();

    expect(gap0Values, {'0', '1'});
    expect(gap1Values, {'0', '1'});
    // Distinct option lists even though the orderIndex values coincide —
    // verified by the rendered text, which differs per gap.
    final gap0Texts = dropdowns[0].items!.map((item) => (item.child as Text).data).toSet();
    final gap1Texts = dropdowns[1].items!.map((item) => (item.child as Text).data).toSet();
    expect(gap0Texts, {'sunny', 'rainy'});
    expect(gap1Texts, {'cold', 'warm'});
    expect(gap0Texts, isNot(gap1Texts));
  });

  testWidgets('selecting an option in one gap does not affect the other gap\'s dropdown', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('rainy').last);
    await tester.pumpAndSettle();

    expect(cubit.state.selectedOrderIndexes, ['1', null]);
  });
}
