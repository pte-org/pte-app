import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_multiple_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

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
    // Every toggle already writes immediately, but if the student never
    // touches this task at all (skips straight to Next), no outbox row
    // exists yet — write the current state (possibly still empty)
    // unconditionally so `SyncEngine.flushOne` always has a row to submit,
    // matching real PTE's "leave it blank, it's just scored wrong" rather
    // than leaving the advance button stuck with nothing to flush.
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: _sortedPayload(state.selectedOrderIndexes),
    );
  }
}
