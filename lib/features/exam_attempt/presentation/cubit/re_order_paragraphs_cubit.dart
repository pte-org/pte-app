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
