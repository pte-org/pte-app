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
    String? initialPayload,
  }) : _outboxDao = outboxDao,
       paragraphs = List.unmodifiable(initialOrder),
       // Seeded directly from the server-delivered (shuffled) order — never
       // re-sorted by orderIndex, or the task becomes trivial.
       super(
         ReOrderParagraphsState(
           currentOrder: _restore(initialOrder, initialPayload),
         ),
       );

  final AnswerOutboxDao _outboxDao;
  final List<TaskOption> paragraphs;
  final String attemptPublicId;
  final String pinnedItemPublicId;

  static List<TaskOption> _restore(List<TaskOption> options, String? payload) {
    final byId = {for (final option in options) option.orderIndex: option};
    final seen = <String>{};
    return [
      for (final id in (payload ?? '').split(','))
        if (byId.containsKey(id) && seen.add(id)) byId[id]!,
    ];
  }

  Future<void> setTargetOrder(List<String> ids) async {
    final updated = _restore(paragraphs, ids.join(','));
    emit(ReOrderParagraphsState(currentOrder: updated));
    await flushPendingEdit();
  }

  @override
  Future<void> flushPendingEdit() async {
    // Include an empty Target so advancing an untouched task submits a blank
    // answer rather than silently using the shuffled Source as the response.
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: state.currentOrder.map((option) => option.orderIndex).join(','),
    );
  }
}
