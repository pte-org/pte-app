import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/listening_payload.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// Toggle-per-word cubit, no selection limit (confirmed with user).
/// Payload is a comma-joined, numerically-sorted word-index list — sorted
/// regardless of toggle order, same rationale as
/// `McListeningMultipleCubit._sortedPayload` (phase-04 Design
/// Constraints).
class HighlightIncorrectWordsCubit
    extends TaskAnswerCubit<HighlightIncorrectWordsState> {
  HighlightIncorrectWordsCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required String audioSource,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(const HighlightIncorrectWordsState()) {
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

  Future<void> toggleWord(int wordIndex) async {
    final updated = Set<int>.of(state.selectedWordIndices);
    if (!updated.remove(wordIndex)) {
      updated.add(wordIndex);
    }
    emit(state.copyWith(selectedWordIndices: updated));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningTranscriptWordIndicesPayload(updated),
    );
  }

  /// Unconditional fallback write for an untouched task (client-side-exam-timer
  /// Phase 4) — see `McListeningSingleCubit.flushPendingEdit`'s doc comment.
  @override
  Future<void> flushPendingEdit() async {
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningTranscriptWordIndicesPayload(state.selectedWordIndices),
    );
  }

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
