import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/mc_reading_multiple_cubit.dart';

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

  group('toggleOption — sorted payload regardless of toggle order (Step 6)', () {
    test('toggling "0" then "2" then "3" writes "0,2,3"', () async {
      final cubit = McReadingMultipleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.toggleOption('0');
      await cubit.toggleOption('2');
      await cubit.toggleOption('3');

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.last, '0,2,3');

      await cubit.close();
    });

    test('toggling in reverse order ("3" then "0" then "2") still writes "0,2,3", not insertion order', () async {
      final cubit = McReadingMultipleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.toggleOption('3');
      await cubit.toggleOption('0');
      await cubit.toggleOption('2');

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.last, '0,2,3');

      await cubit.close();
    });

    test('untoggling a selected option removes it from the sorted payload', () async {
      final cubit = McReadingMultipleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.toggleOption('0');
      await cubit.toggleOption('2');
      await cubit.toggleOption('3');
      await cubit.toggleOption('2');

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.last, '0,3');

      await cubit.close();
    });

    test('untoggling every selected option writes an empty-string payload, not an omitted write', () async {
      final cubit = McReadingMultipleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.toggleOption('0');
      await cubit.toggleOption('0');

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured, hasLength(2));
      expect(captured.last, '');

      await cubit.close();
    });

    test('emits state with the toggled orderIndex present in selectedOrderIndexes', () async {
      final cubit = McReadingMultipleCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
      );

      await cubit.toggleOption('1');

      expect(cubit.state.selectedOrderIndexes, {'1'});

      await cubit.close();
    });
  });

  group('flushPendingEdit — writes current state unconditionally (no debounce to cancel, but a never-touched task '
      'must still leave a submittable row)', () {
    test('with no prior toggle, writes an empty-payload row so skipping without answering still submits', () async {
      final cubit = McReadingMultipleCubit(
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
  });
}
