import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../domain/task_view.dart';
import 're_order_paragraphs_state.dart';
import 'task_answer_cubit.dart';

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
    // Each reorder already writes immediately — nothing left to flush.
    // Implemented as a no-op (not omitted) so the shared advance button can
    // call every task-type cubit uniformly through `FlushableAnswerCubit`.
  }
}
