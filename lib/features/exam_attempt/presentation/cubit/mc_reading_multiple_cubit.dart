import '../../../../core/storage/dao/answer_outbox_dao.dart';
import 'mc_reading_multiple_state.dart';
import 'task_answer_cubit.dart';

/// A discrete toggle event per checkbox — writes immediately on every
/// toggle, no debounce needed (mirrors `McReadingSingleCubit`, phase-05
/// Design Constraints extended to this task type per
/// `ninh-pte-reading-task-types` plan.md Research Summary item 7).
class McReadingMultipleCubit extends TaskAnswerCubit<McReadingMultipleState> {
  McReadingMultipleCubit({
    required AnswerOutboxDao outboxDao,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
  }) : _outboxDao = outboxDao,
       super(const McReadingMultipleState());

  final AnswerOutboxDao _outboxDao;
  final String attemptPublicId;
  final String pinnedItemPublicId;

  Future<void> toggleOption(String orderIndex) async {
    final updated = Set<String>.of(state.selectedOrderIndexes);
    if (!updated.remove(orderIndex)) {
      updated.add(orderIndex);
    }
    emit(state.copyWith(selectedOrderIndexes: updated));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: _sortedPayload(updated),
    );
  }

  /// Payload is a comma-joined, numerically-sorted-ascending `orderIndex`
  /// list — sorted regardless of toggle order, since `Set` iteration order
  /// is unspecified in Dart (phase-03 Design Constraints/Risks).
  String _sortedPayload(Set<String> orderIndexes) {
    final sorted = orderIndexes.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return sorted.join(',');
  }

  @override
  Future<void> flushPendingEdit() async {
    // Selection already writes immediately on every toggle — nothing left
    // to flush. Implemented as a no-op (not omitted) so the shared advance
    // button can call every task-type cubit uniformly through
    // `FlushableAnswerCubit` regardless of whether it debounces.
  }
}
