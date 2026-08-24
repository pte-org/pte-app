import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../domain/positional_payload.dart';
import '../../domain/task_view.dart';
import 'fill_blanks_drag_drop_state.dart';
import 'task_answer_cubit.dart';

/// A discrete drop/undo event per gap — writes immediately, no debounce
/// needed (mirrors `McReadingSingleCubit`, phase-05 Design Constraints
/// extended to this task type per `ninh-pte-reading-task-types` plan.md
/// Research Summary item 7).
class FillBlanksDragDropCubit extends TaskAnswerCubit<FillBlanksDragDropState> {
  FillBlanksDragDropCubit({
    required AnswerOutboxDao outboxDao,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required this.gapCount,
  }) : _outboxDao = outboxDao,
       super(const FillBlanksDragDropState());

  final AnswerOutboxDao _outboxDao;
  final String attemptPublicId;
  final String pinnedItemPublicId;

  /// Total number of gaps in this task's passage — the positional payload
  /// always has exactly this many comma-separated entries, regardless of
  /// how many are currently filled (phase-05 Design Constraints).
  final int gapCount;

  /// Assigns [option] to [gapIndex], clearing any other gap this option is
  /// currently occupying first — an option can never occupy two gaps at
  /// once, whether dragged from the bank or from another gap.
  Future<void> assignToGap(int gapIndex, TaskOption option) async {
    final updated = Map<int, TaskOption>.of(state.gapAssignments)
      ..removeWhere((_, assigned) => assigned.orderIndex == option.orderIndex)
      ..[gapIndex] = option;
    await _emitAndPersist(updated);
  }

  /// Removes whatever word is placed at [gapIndex] (a no-op if the gap is
  /// already empty), returning it to the shared word bank.
  Future<void> clearGap(int gapIndex) async {
    if (!state.gapAssignments.containsKey(gapIndex)) return;
    final updated = Map<int, TaskOption>.of(state.gapAssignments)..remove(gapIndex);
    await _emitAndPersist(updated);
  }

  Future<void> _emitAndPersist(Map<int, TaskOption> updated) async {
    emit(state.copyWith(gapAssignments: updated));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: positionalPayload(List.generate(gapCount, (gapIndex) => updated[gapIndex]?.orderIndex)),
    );
  }

  @override
  Future<void> flushPendingEdit() async {
    // Every drop/undo already writes immediately, but if the student never
    // touches this task at all (skips straight to Next), no outbox row
    // exists yet — write the current state (possibly still all-empty)
    // unconditionally so `SyncEngine.flushOne` always has a row to submit,
    // matching real PTE's "leave it blank, it's just scored wrong" rather
    // than leaving the advance button stuck with nothing to flush.
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: positionalPayload(List.generate(gapCount, (gapIndex) => state.gapAssignments[gapIndex]?.orderIndex)),
    );
  }
}
