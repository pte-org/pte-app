import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/word_count.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/write_from_dictation_state.dart';

/// Discrete-input cubit (no debounce, unlike `WriteEssayCubit`) — every
/// keystroke writes to the outbox synchronously (phase-02 Design
/// Constraints). Starts audio playback on construction; the screen never
/// calls `play()` itself.
class WriteFromDictationCubit extends TaskAnswerCubit<WriteFromDictationState> {
  WriteFromDictationCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required String audioSource,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(const WriteFromDictationState()) {
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

  /// Every keystroke already writes synchronously, but if the student never
  /// types anything at all (client-side-exam-timer Phase 4), `_persist()`
  /// has never been called — call it unconditionally so `SyncEngine.flushOne`
  /// always has a row to submit, matching `McReadingSingleCubit`'s fallback.
  @override
  Future<void> flushPendingEdit() => _persist();

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
