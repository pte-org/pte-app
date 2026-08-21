import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/re_order_paragraphs_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/re_order_paragraphs_list.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

const _paragraphs = [
  TaskOption(text: 'Second paragraph.', orderIndex: '1'),
  TaskOption(text: 'First paragraph.', orderIndex: '0'),
];

void main() {
  late _MockAnswerOutboxDao outboxDao;
  late ReOrderParagraphsCubit cubit;

  setUp(() {
    outboxDao = _MockAnswerOutboxDao();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    cubit = ReOrderParagraphsCubit(
      outboxDao: outboxDao,
      attemptPublicId: 'attempt-1',
      pinnedItemPublicId: 'item-1',
      initialOrder: _paragraphs,
    );
  });

  tearDown(() => cubit.close());

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ReOrderParagraphsCubit>.value(value: cubit, child: const ReOrderParagraphsList()),
      ),
    );
  }

  // ReorderableListView's built-in long-press-then-drag gesture is not
  // reliably simulatable in a widget test (a documented limitation of this
  // widget in Flutter test environments) — this test verifies rendering
  // and Semantics labeling instead; actual drag behavior is verified via
  // the cubit-level `reorder()` unit tests, which cover the payload-shape
  // correctness that matters most.
  testWidgets('renders every paragraph in its current order with a position-reflecting Semantics label', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Second paragraph.'), findsOneWidget);
    expect(find.text('First paragraph.'), findsOneWidget);
    expect(find.bySemanticsLabel('Paragraph, position 1 of 2, draggable'), findsOneWidget);
    expect(find.bySemanticsLabel('Paragraph, position 2 of 2, draggable'), findsOneWidget);
  });
}
