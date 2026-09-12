import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/listening_payload.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_single_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// Mirrors `McReadingSingleCubit` exactly, plus the audio-on-construction
/// lifecycle every listening cubit needs (phase-03 Design Constraints).
class McListeningSingleCubit extends TaskAnswerCubit<McListeningSingleState> {
  McListeningSingleCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required String audioSource,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(const McListeningSingleState()) {
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
      payload: listeningSingleSelectionPayload(orderIndex),
    );
  }

  /// Every selection already writes immediately, but if the student never
  /// touches this task at all (skips straight to Next, or its local
  /// countdown reaches zero untouched — client-side-exam-timer Phase 4), no
  /// outbox row exists yet — write the current state (possibly still
  /// unanswered) unconditionally so `SyncEngine.flushOne` always has a row
  /// to submit, matching `McReadingSingleCubit`'s identical fallback.
  @override
  Future<void> flushPendingEdit() async {
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningSingleSelectionPayload(state.selectedOrderIndex ?? ''),
    );
  }

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
