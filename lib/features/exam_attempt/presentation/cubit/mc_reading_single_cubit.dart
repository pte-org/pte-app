import '../../../../core/storage/dao/answer_outbox_dao.dart';
import 'mc_reading_single_state.dart';
import 'task_answer_cubit.dart';

/// A single discrete selection event — writes immediately on selection, no
/// debounce needed for a single tap (phase-05 Design Constraints). Writes
/// only to the local outbox (`AnswerOutboxDao.upsertAnswer`); the row is
/// excluded from background flush while this task is active (Phase 2), so
/// this write never itself triggers a network submission.
class McReadingSingleCubit extends TaskAnswerCubit<McReadingSingleState> {
  McReadingSingleCubit({
    required AnswerOutboxDao outboxDao,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
  }) : _outboxDao = outboxDao,
       super(const McReadingSingleState());

  final AnswerOutboxDao _outboxDao;
  final String attemptPublicId;
  final String pinnedItemPublicId;

  Future<void> selectOption(String orderIndex) async {
    emit(state.copyWith(selectedOrderIndex: orderIndex));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: orderIndex,
    );
  }

  @override
  Future<void> flushPendingEdit() async {
    // Selection already writes immediately on every change — nothing left
    // to flush. Implemented as a no-op (not omitted) so the shared advance
    // button can call every task-type cubit uniformly through
    // `FlushableAnswerCubit` regardless of whether it debounces.
  }
}
