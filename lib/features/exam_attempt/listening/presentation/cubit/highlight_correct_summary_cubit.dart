import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_correct_summary_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// Single-select, structurally identical to `McListeningSingleCubit` —
/// real PTE format is pick-the-one-correct-summary, not multi-toggle
/// (corrected during red-team review; see plan.md Research Summary #5).
class HighlightCorrectSummaryCubit extends TaskAnswerCubit<HighlightCorrectSummaryState> {
  HighlightCorrectSummaryCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required String audioSource,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(const HighlightCorrectSummaryState()) {
    _finishedSubscription = _audioPlayerService.hasFinishedPlaying.listen((_) {
      emit(state.copyWith(hasFinishedPlaying: true));
    });
    unawaited(_audioPlayerService.play(audioSource));
  }

  final AnswerOutboxDao _outboxDao;
  final AudioPlayerService _audioPlayerService;
  final String attemptPublicId;
  final String pinnedItemPublicId;
  late final StreamSubscription<bool> _finishedSubscription;

  Future<void> selectOption(String orderIndex) async {
    emit(state.copyWith(selectedOrderIndex: orderIndex));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: orderIndex,
    );
  }

  /// Unconditional fallback write for an untouched task (client-side-exam-timer
  /// Phase 4) — see `McListeningSingleCubit.flushPendingEdit`'s doc comment.
  @override
  Future<void> flushPendingEdit() async {
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: state.selectedOrderIndex ?? '',
    );
  }

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
