import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// A discrete drop event per reorder — writes immediately, no debounce
/// needed (mirrors `McReadingSingleCubit`, phase-05 Design Constraints
/// extended to this task type per `ninh-pte-reading-task-types` plan.md
/// Research Summary item 7).
class ReOrderParagraphsCubit extends TaskAnswerCubit<ReOrderParagraphsState> {
  ReOrderParagraphsCubit({
    required AnswerOutboxDao outboxDao,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required List<TaskOption> initialOrder,
  }) : _outboxDao = outboxDao,
       // Seeded directly from the server-delivered (shuffled) order — never
       // re-sorted by orderIndex, or the task becomes trivial.
       super(ReOrderParagraphsState(currentOrder: initialOrder));

  final AnswerOutboxDao _outboxDao;
  final String attemptPublicId;
  final String pinnedItemPublicId;

  /// [newIndex] must already be adjusted for the removed item at
  /// [oldIndex] (i.e. the item's actual final resting index) — the caller
  /// (`ReOrderParagraphsList`'s `ReorderableListView.onReorder` handler) is
  /// responsible for that adjustment, since `onReorder` itself reports
  /// `newIndex` as the pre-removal insertion point.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final updated = List<TaskOption>.of(state.currentOrder);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    emit(ReOrderParagraphsState(currentOrder: updated));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: updated.map((option) => option.orderIndex).join(','),
    );
  }

  @override
  Future<void> flushPendingEdit() async {
    // Every reorder already writes immediately, but if the student never
    // touches this task at all (skips straight to Next), no outbox row
    // exists yet — write the current state (the server-shuffled order,
    // unchanged) unconditionally so `SyncEngine.flushOne` always has a row
    // to submit, matching real PTE's "leave it as shown, it's just scored
    // wrong" rather than leaving the advance button stuck with nothing to
    // flush.
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: state.currentOrder.map((option) => option.orderIndex).join(','),
    );
  }
}
