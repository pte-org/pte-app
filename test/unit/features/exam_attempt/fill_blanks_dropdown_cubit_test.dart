import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_cubit.dart';

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

  FillBlanksDropdownCubit buildCubit({required int blankGroupCount}) {
    return FillBlanksDropdownCubit(
      outboxDao: outboxDao,
      attemptPublicId: 'attempt-1',
      pinnedItemPublicId: 'item-1',
      blankGroupCount: blankGroupCount,
    );
  }

  List<String> capturedPayloads() {
    return verify(
      () => outboxDao.upsertAnswer(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        payload: captureAny(named: 'payload'),
      ),
    ).captured.cast<String>();
  }

  group('selectOption — positional payload correctness', () {
    test('single-gap task writes the one entry', () async {
      final cubit = buildCubit(blankGroupCount: 1);

      await cubit.selectOption(0, '2');

      expect(capturedPayloads().last, '2');
      await cubit.close();
    });

    test('multi-gap task writes entries in gap-index order regardless of selection order', () async {
      final cubit = buildCubit(blankGroupCount: 3);

      await cubit.selectOption(2, '1');
      await cubit.selectOption(0, '0');

      expect(capturedPayloads().last, '0,,1');
      await cubit.close();
    });

    test('the required trailing empty entry is preserved for an unanswered final gap', () async {
      final cubit = buildCubit(blankGroupCount: 3);

      await cubit.selectOption(0, '2');
      await cubit.selectOption(1, '0');

      final payload = capturedPayloads().last;
      expect(payload, '2,0,');
      expect(payload.split(','), hasLength(3));
      await cubit.close();
    });

    test('re-selecting a gap overwrites its previous choice without affecting other gaps', () async {
      final cubit = buildCubit(blankGroupCount: 2);

      await cubit.selectOption(0, '1');
      await cubit.selectOption(1, '2');
      await cubit.selectOption(0, '0');

      expect(capturedPayloads().last, '0,2');
      await cubit.close();
    });
  });

  group('flushPendingEdit — writes current state unconditionally (no debounce to cancel, but a never-touched task '
      'must still leave a submittable row)', () {
    test('with no prior selection, writes an all-empty-gaps payload so skipping without answering still submits', () async {
      final cubit = buildCubit(blankGroupCount: 1);

      await cubit.flushPendingEdit();

      verify(
        () => outboxDao.upsertAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'item-1', payload: ''),
      ).called(1);
      await cubit.close();
    });
  });
}
