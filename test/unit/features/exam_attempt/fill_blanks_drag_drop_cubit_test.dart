import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_drag_drop_cubit.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

const _wordA = TaskOption(text: 'quickly', orderIndex: '0');
const _wordB = TaskOption(text: 'rarely', orderIndex: '1');
const _wordC = TaskOption(text: 'always', orderIndex: '2');

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

  FillBlanksDragDropCubit buildCubit({required int gapCount}) {
    return FillBlanksDragDropCubit(
      outboxDao: outboxDao,
      attemptPublicId: 'attempt-1',
      pinnedItemPublicId: 'item-1',
      gapCount: gapCount,
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

  group('assignToGap — positional payload correctness', () {
    test('single-gap task assigns and writes the one entry', () async {
      final cubit = buildCubit(gapCount: 1);

      await cubit.assignToGap(0, _wordA);

      expect(capturedPayloads().last, '0');
      await cubit.close();
    });

    test('multi-gap task writes one entry per gap in gap-index order', () async {
      final cubit = buildCubit(gapCount: 3);

      await cubit.assignToGap(0, _wordC);
      await cubit.assignToGap(1, _wordA);
      await cubit.assignToGap(2, _wordB);

      expect(capturedPayloads().last, '2,0,1');
      await cubit.close();
    });

    test('reassigning an already-placed option to a different gap clears its old gap first', () async {
      final cubit = buildCubit(gapCount: 3);

      await cubit.assignToGap(0, _wordA);
      await cubit.assignToGap(2, _wordA); // same option, new gap

      expect(cubit.state.gapAssignments, {2: _wordA});
      expect(capturedPayloads().last, ',,0');
      await cubit.close();
    });
  });

  group('clearGap', () {
    test('produces the correct empty entry at that position', () async {
      final cubit = buildCubit(gapCount: 2);

      await cubit.assignToGap(0, _wordA);
      await cubit.assignToGap(1, _wordB);
      await cubit.clearGap(0);

      expect(capturedPayloads().last, ',1');
      await cubit.close();
    });

    test('clearing an already-empty gap is a no-op (no extra outbox write)', () async {
      final cubit = buildCubit(gapCount: 2);

      await cubit.clearGap(0);

      verifyNever(
        () => outboxDao.upsertAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      );
      await cubit.close();
    });
  });

  group('unanswered-trailing-gap empty-entry requirement (HIGH risk regression, Step 7)', () {
    test('a 3-gap task with only gap 0 and 1 filled writes "x,y," — trailing comma preserved, not "x,y"', () async {
      final cubit = buildCubit(gapCount: 3);

      await cubit.assignToGap(0, _wordC);
      await cubit.assignToGap(1, _wordA);

      final payload = capturedPayloads().last;
      expect(payload, '2,0,');
      expect(payload.split(',', ), hasLength(3));
      await cubit.close();
    });

    test('only the middle gap filled writes a leading and trailing empty entry: ",0,"', () async {
      final cubit = buildCubit(gapCount: 3);

      await cubit.assignToGap(1, _wordA);

      expect(capturedPayloads().last, ',0,');
      await cubit.close();
    });
  });

  group('flushPendingEdit — writes current state unconditionally (no debounce to cancel, but a never-touched task '
      'must still leave a submittable row)', () {
    test('with no prior drop, writes an all-empty-gaps payload so skipping without answering still submits', () async {
      final cubit = buildCubit(gapCount: 1);

      await cubit.flushPendingEdit();

      verify(
        () => outboxDao.upsertAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'item-1', payload: ''),
      ).called(1);
      await cubit.close();
    });
  });
}
