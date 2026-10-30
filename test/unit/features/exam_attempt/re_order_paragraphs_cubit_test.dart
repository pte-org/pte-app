import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_cubit.dart';

class _Dao extends Mock implements AnswerOutboxDao {}

const options = [
  TaskOption(text: 'B', orderIndex: '9'),
  TaskOption(text: 'A', orderIndex: '4'),
];
void main() {
  late _Dao dao;
  setUp(() {
    dao = _Dao();
    when(
      () => dao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });
  ReOrderParagraphsCubit create([String? payload]) => ReOrderParagraphsCubit(
    outboxDao: dao,
    attemptPublicId: 'a',
    pinnedItemPublicId: 'i',
    initialOrder: options,
    initialPayload: payload,
  );
  test(
    'new task has empty Target and preserves shuffled Source identities',
    () async {
      final cubit = create();
      expect(cubit.state.currentOrder, isEmpty);
      expect(cubit.paragraphs.map((o) => o.orderIndex), ['9', '4']);
      await cubit.flushPendingEdit();
      verify(
        () => dao.upsertAnswer(
          attemptPublicId: 'a',
          pinnedItemPublicId: 'i',
          payload: '',
        ),
      ).called(1);
      await cubit.close();
    },
  );
  test(
    'partial, full and emptied Target persist unchanged CSV identities',
    () async {
      final cubit = create();
      for (final ids in [
        ['4'],
        ['4', '9'],
        ['9', '4'],
        <String>[],
      ]) {
        await cubit.setTargetOrder(ids);
        expect(cubit.state.currentOrder.map((o) => o.orderIndex), ids);
        verify(
          () => dao.upsertAnswer(
            attemptPublicId: 'a',
            pinnedItemPublicId: 'i',
            payload: ids.join(','),
          ),
        ).called(1);
        final restored = create(ids.join(','));
        expect(restored.state.currentOrder.map((o) => o.orderIndex), ids);
        await restored.close();
      }
      await cubit.close();
    },
  );
  test(
    'invalid and duplicate saved IDs cannot duplicate or lose Source paragraphs',
    () async {
      final cubit = create('4,invalid,4');
      expect(cubit.state.currentOrder.map((o) => o.orderIndex), ['4']);
      expect(cubit.paragraphs, options);
      await cubit.close();
    },
  );
}
