import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/positional_payload.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// A discrete selection event per gap — writes immediately, no debounce
/// needed (mirrors `McReadingSingleCubit`/`FillBlanksDragDropCubit`,
/// phase-05 Design Constraints extended to this task type per
/// `ninh-pte-reading-task-types` plan.md Research Summary item 7).
class FillBlanksDropdownCubit extends TaskAnswerCubit<FillBlanksDropdownState> {
  FillBlanksDropdownCubit({
    required AnswerOutboxDao outboxDao,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required int blankGroupCount,
  }) : _outboxDao = outboxDao,
       super(FillBlanksDropdownState(selectedOrderIndexes: List<String?>.filled(blankGroupCount, null)));

  final AnswerOutboxDao _outboxDao;
  final String attemptPublicId;
  final String pinnedItemPublicId;

  /// [orderIndex] must come from `task.blankGroups![gapIndex].options` —
  /// each gap's own distinct list, never another gap's or the shared
  /// `options` field (this is the defining property of this task type vs.
  /// `FILL_IN_THE_BLANKS_DRAG_AND_DROP`'s shared word bank).
  Future<void> selectOption(int gapIndex, String orderIndex) async {
    final updated = List<String?>.of(state.selectedOrderIndexes);
    updated[gapIndex] = orderIndex;
    emit(state.copyWith(selectedOrderIndexes: updated));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: positionalPayload(updated),
    );
  }

  @override
  Future<void> flushPendingEdit() async {
    // Every selection already writes immediately, but if the student never
    // touches this task at all (skips straight to Next), no outbox row
    // exists yet — write the current state (possibly still all-empty)
    // unconditionally so `SyncEngine.flushOne` always has a row to submit,
    // matching real PTE's "leave it blank, it's just scored wrong" rather
    // than leaving the advance button stuck with nothing to flush.
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: positionalPayload(state.selectedOrderIndexes),
    );
  }
}
