import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/word_count.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/summarize_spoken_text_state.dart';

/// Same discrete-input, no-debounce shape as `WriteFromDictationCubit`
/// (phase-02 Design Constraints) — kept as a separate class rather than a
/// shared generic, matching this codebase's existing per-type duplication
/// convention (e.g. `McReadingSingleCubit`/`McReadingMultipleCubit`).
class SummarizeSpokenTextCubit extends TaskAnswerCubit<SummarizeSpokenTextState> {
  SummarizeSpokenTextCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required String audioSource,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(const SummarizeSpokenTextState()) {
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

  void draftChanged(String text) {
    emit(state.copyWith(draftText: text, wordCount: countWords(text)));
    unawaited(_persist());
  }

  Future<void> _persist() {
    return _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: state.draftText,
    );
  }

  @override
  Future<void> flushPendingEdit() async {}

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
