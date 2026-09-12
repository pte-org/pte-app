import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/listening_payload.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/fill_blanks_listening_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// Free type-in per gap, no word bank/dropdown — reuses `positionalPayload`
/// (the same gap-position comma-join both Reading fill-blank cubits use)
/// rather than hand-rolling trailing-comma logic (phase-05 Design
/// Constraints). Never owns a `TextEditingController` — the screen owns
/// all of them (phase-02's corrected disposal split, phase-05 Design
/// Constraints).
class FillBlanksListeningCubit
    extends TaskAnswerCubit<FillBlanksListeningState> {
  FillBlanksListeningCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required int gapCount,
    required String audioSource,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(
         FillBlanksListeningState(answers: List<String>.filled(gapCount, '')),
       ) {
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

  Future<void> gapChanged(int gapIndex, String text) async {
    final updated = List<String>.of(state.answers);
    updated[gapIndex] = text;
    emit(state.copyWith(answers: updated));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningPositionalTextPayload(updated),
    );
  }

  /// Unconditional fallback write for an untouched task (client-side-exam-timer
  /// Phase 4) — see `McListeningSingleCubit.flushPendingEdit`'s doc comment.
  @override
  Future<void> flushPendingEdit() async {
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningPositionalTextPayload(state.answers),
    );
  }

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
