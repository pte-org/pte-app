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

  /// [newIndex] arrives pre-adjusted for the removed item at [oldIndex] —
  /// this is `ReorderableListView.onReorderItem`'s contract (`onReorder` is
  /// deprecated and required a manual off-by-one adjustment `onReorderItem`
  /// no longer needs).
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
    // Each reorder already writes immediately — nothing left to flush.
    // Implemented as a no-op (not omitted) so the shared advance button can
    // call every task-type cubit uniformly through `FlushableAnswerCubit`.
  }
}
