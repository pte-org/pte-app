import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/mc_reading_single_cubit.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

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

  group('selectOption — payload-shape assertion (Step 7)', () {
    test('selecting orderIndex "2" writes the literal decimal string "2", not the int 2', () async {
      final cubit = McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.selectOption('2');

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured, hasLength(1));
      expect(captured.single, isA<String>());
      expect(captured.single, '2');

      await cubit.close();
    });

    test(
      'selecting an out-of-list-order orderIndex writes that exact orderIndex value, never the list position '
      '(rules out an off-by-one list-index-vs-orderIndex bug)',
      () async {
        // Simulates options rendered in one order but carrying orderIndex
        // values that differ from their list position — e.g. the option at
        // list position 0 actually has orderIndex "5".
        final cubit = McReadingSingleCubit(
          outboxDao: outboxDao,
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
        );

        await cubit.selectOption('5');

        final captured = verify(
          () => outboxDao.upsertAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: captureAny(named: 'payload'),
          ),
        ).captured;
        expect(captured.single, '5');
        expect(captured.single, isNot('0')); // not the list position

        await cubit.close();
      },
    );

    test('selecting a multi-digit orderIndex writes it verbatim, not truncated or reformatted', () async {
      final cubit = McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.selectOption('12');

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, '12');

      await cubit.close();
    });

    test('emits state with selectedOrderIndex set to the chosen value', () async {
      final cubit = McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.selectOption('2');

      expect(cubit.state.selectedOrderIndex, '2');

      await cubit.close();
    });

    test('every upsertAnswer call carries the pinnedItemPublicId from construction, never a stale value', () async {
      final cubit = McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-9',
        pinnedItemPublicId: 'item-9',
      );

      await cubit.selectOption('1');

      verify(
        () => outboxDao.upsertAnswer(attemptPublicId: 'attempt-9', pinnedItemPublicId: 'item-9', payload: '1'),
      ).called(1);

      await cubit.close();
    });
  });

  group('flushPendingEdit — writes current state unconditionally (no debounce to cancel, but a never-touched task '
      'must still leave a submittable row)', () {
    test('with no prior selection, writes an empty-payload row so skipping without answering still submits', () async {
      final cubit = McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.flushPendingEdit();

      verify(
        () => outboxDao.upsertAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'item-1', payload: ''),
      ).called(1);

      await cubit.close();
    });

    test('with a prior selection, re-writes the same payload rather than skipping the call', () async {
      final cubit = McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.selectOption('2');
      await cubit.flushPendingEdit();

      verify(
        () => outboxDao.upsertAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'item-1', payload: '2'),
      ).called(2);

      await cubit.close();
    });
  });
}
