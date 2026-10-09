import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/answer_payload_parser.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/listening_payload.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_correct_summary_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// Single-select, structurally identical to `McListeningSingleCubit` —
/// real PTE format is pick-the-one-correct-summary, not multi-toggle
/// (corrected during red-team review; see plan.md Research Summary #5).
class HighlightCorrectSummaryCubit
    extends TaskAnswerCubit<HighlightCorrectSummaryState> {
  HighlightCorrectSummaryCubit({
    required AnswerOutboxDao outboxDao,
    required AudioPlayerService audioPlayerService,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    required String audioSource,
    String? initialPayload,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       super(
         HighlightCorrectSummaryState(
           selectedOrderIndex: singleSelectionFromAnswerPayload(initialPayload),
         ),
         answerChanged:
             (
               HighlightCorrectSummaryState current,
               HighlightCorrectSummaryState initial,
             ) => current.selectedOrderIndex != initial.selectedOrderIndex,
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

  Future<void> selectOption(String orderIndex) async {
    emit(state.copyWith(selectedOrderIndex: orderIndex));
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningSingleSelectionPayload(orderIndex),
    );
  }

  /// Unconditional fallback write for an untouched task (client-side-exam-timer
  /// Phase 4) — see `McListeningSingleCubit.flushPendingEdit`'s doc comment.
  @override
  Future<void> flushPendingEdit() async {
    await _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningSingleSelectionPayload(state.selectedOrderIndex ?? ''),
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
