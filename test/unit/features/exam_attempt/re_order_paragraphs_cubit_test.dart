import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/re_order_paragraphs_cubit.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

// Deliberately shuffled so identity (orderIndex) and current list position
// diverge from the very first frame — a naive implementation that
// accidentally payloads list position instead of orderIndex would produce
// "0,1,2,3" here, which every test below explicitly rules out.
List<TaskOption> _shuffledParagraphs() {
  return const [
    TaskOption(text: 'Finally, the team published their findings.', orderIndex: '3'),
    TaskOption(text: 'First, the researchers gathered samples.', orderIndex: '0'),
    TaskOption(text: 'The samples were analyzed over months.', orderIndex: '1'),
    TaskOption(text: 'Unexpected patterns emerged.', orderIndex: '2'),
  ];
}

void main() {
  late _MockAnswerOutboxDao outboxDao;

  setUp(() {
    outboxDao = _MockAnswerOutboxDao();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  group('initial state — seeded from server-shuffled order, never re-sorted', () {
    test('currentOrder matches the exact server-delivered order', () {
      final cubit = ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        initialOrder: _shuffledParagraphs(),
      );

      expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['3', '0', '1', '2']);

      cubit.close();
    });
  });

  group('reorder — payload is identity orderIndex sequence, not list position (Step 6)', () {
    test('moving the first item to the end writes the new identity sequence', () async {
      final cubit = ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        initialOrder: _shuffledParagraphs(),
      );

      // onReorderItem's newIndex is already adjusted for the removed item.
      await cubit.reorder(0, 3);

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.last, '0,1,2,3');
      expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['0', '1', '2', '3']);

      await cubit.close();
    });

    test('multiple sequential reorders each independently produce the correct payload', () async {
      final cubit = ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        initialOrder: _shuffledParagraphs(),
      );

      await cubit.reorder(0, 3); // '3','0','1','2' -> '0','1','2','3'
      await cubit.reorder(0, 1); // '0','1','2','3' -> '1','0','2','3'

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured, hasLength(2));
      expect(captured[0], '0,1,2,3');
      expect(captured[1], '1,0,2,3');

      await cubit.close();
    });

    test('a no-op reorder (item dropped back at its own position) still writes the unchanged identity sequence', () async {
      final cubit = ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        initialOrder: _shuffledParagraphs(),
      );

      await cubit.reorder(0, 0);

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, '3,0,1,2');

      await cubit.close();
    });
  });

  group('flushPendingEdit — writes current state unconditionally (no debounce to cancel, but a never-touched task '
      'must still leave a submittable row)', () {
    test('with no prior reorder, writes the untouched server-shuffled order as the payload', () async {
      final cubit = ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        initialOrder: _shuffledParagraphs(),
      );

      await cubit.flushPendingEdit();

      verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: '3,0,1,2',
        ),
      ).called(1);

      await cubit.close();
    });
  });
}
