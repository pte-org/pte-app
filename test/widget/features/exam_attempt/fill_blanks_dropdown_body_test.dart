import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/inline_blank_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_dropdown_body.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

TaskView _task({bool oneBased = false}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 0,
    totalTasks: 5,
    section: 'READING',
    taskType: 'FILL_IN_THE_BLANKS_DROPDOWN',
    title: 'title',
    promptText: oneBased
        ? 'It was {{1}} but {{2}}.'
        : 'It was {{0}} but {{1}}.',
    blankGroups: const [
      BlankGroup(
        blankIndex: 0,
        options: [
          TaskOption(text: 'sunny', orderIndex: '0'),
          TaskOption(text: 'rainy', orderIndex: '1'),
        ],
      ),
      BlankGroup(
        blankIndex: 1,
        options: [
          TaskOption(text: 'cold', orderIndex: '0'),
          TaskOption(text: 'warm', orderIndex: '1'),
        ],
      ),
    ],
    prepSeconds: 0,
    responseSeconds: 60,
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

  Widget buildSubject({bool oneBased = false}) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<FillBlanksDropdownCubit>.value(
          value: cubit,
          child: FillBlanksDropdownBody(task: _task(oneBased: oneBased)),
        ),
      ),
    );
  }

  testWidgets(
    'each gap renders as an independent DropdownButton with only its own gap\'s options',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      final dropdowns = tester
          .widgetList<InlineBlankDropdown>(find.byType(InlineBlankDropdown))
          .toList();
      expect(dropdowns, hasLength(2));

      final gap0Values = dropdowns[0].options.map((item) => item.value).toSet();
      final gap1Values = dropdowns[1].options.map((item) => item.value).toSet();

      expect(gap0Values, {'0', '1'});
      expect(gap1Values, {'0', '1'});
      // Distinct option lists even though the orderIndex values coincide —
      // verified by the rendered text, which differs per gap.
      final gap0Texts = dropdowns[0].options.map((item) => item.text).toSet();
      final gap1Texts = dropdowns[1].options.map((item) => item.text).toSet();
      expect(gap0Texts, {'sunny', 'rainy'});
      expect(gap1Texts, {'cold', 'warm'});
      expect(gap0Texts, isNot(gap1Texts));
    },
  );

  testWidgets('one-based prompt markers map to zero-based saved answer slots', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(oneBased: true));
    expect(find.byType(InlineBlankDropdown), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('inlineBlank-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('warm').last);
    await tester.pumpAndSettle();
    expect(cubit.state.selectedOrderIndexes, [null, '1']);
    verify(
      () => outboxDao.upsertAnswer(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        payload: ',1',
      ),
    ).called(1);
  });

  testWidgets(
    'selecting an option in one gap does not affect the other gap\'s dropdown',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byType(InlineBlankDropdown).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('rainy').last);
      await tester.pumpAndSettle();

      expect(cubit.state.selectedOrderIndexes, ['1', null]);
    },
  );
}
