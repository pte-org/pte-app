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
    // Every selection already writes immediately, but if the student never
    // touches this task at all (skips straight to Next), no outbox row
    // exists yet — write the current state (possibly still unanswered)
    // unconditionally so `SyncEngine.flushOne` always has a row to submit,
    // matching real PTE's "leave it blank, it's just scored wrong" rather
    // than leaving the advance button stuck with nothing to flush.
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: state.selectedOrderIndex ?? '',
    );
  }
}
