import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/answer_payload_parser.dart';
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
    String? initialPayload,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(
         FillBlanksListeningState(
           answers: positionalValuesFromAnswerPayload(
             initialPayload,
             length: gapCount,
           ),
         ),
         answerChanged:
             (
               FillBlanksListeningState current,
               FillBlanksListeningState initial,
             ) => current.answers != initial.answers,
       ) {
    _finishedSubscription = _audioPlayerService.hasFinishedPlaying.listen((_) {
      emit(state.copyWith(hasFinishedPlaying: true));
    });
    _positionSubscription = _audioPlayerService.position.listen(_onPosition);
    _durationSubscription = _audioPlayerService.duration.listen(_onDuration);
    unawaited(_audioPlayerService.play(audioSource));
  }

  final AnswerOutboxDao _outboxDao;
  final AudioPlayerService _audioPlayerService;
  final String attemptPublicId;
  final String pinnedItemPublicId;
  late final StreamSubscription<bool> _finishedSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  Duration _lastPosition = Duration.zero;
  Duration? _lastDuration;

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

  void _onPosition(Duration position) {
    _lastPosition = position;
    _emitProgress();
  }

  void _onDuration(Duration? duration) {
    _lastDuration = duration;
    _emitProgress();
  }

  void _emitProgress() {
    if (state.hasFinishedPlaying) return;
    final duration = _lastDuration;
    final progress = (duration == null || duration <= Duration.zero)
        ? 0.0
        : (_lastPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    emit(state.copyWith(progress: progress));
  }

  @override
  Future<void> close() async {
    await _finishedSubscription.cancel();
    await _positionSubscription.cancel();
    await _durationSubscription.cancel();
    await _audioPlayerService.close();
    return super.close();
  }
}
