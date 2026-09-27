import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/answer_payload_parser.dart';
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
    String? initialPayload,
    bool isPractice = false,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       _audioSource = audioSource,
       super(
         HighlightIncorrectWordsState(
           selectedWordIndices: indicesFromAnswerPayload(initialPayload),
           hasStartedPlaying: !isPractice,
         ),
         answerChanged:
             (
               HighlightIncorrectWordsState current,
               HighlightIncorrectWordsState initial,
             ) => current.selectedWordIndices != initial.selectedWordIndices,
       ) {
    _finishedSubscription = _audioPlayerService.hasFinishedPlaying.listen((_) {
      emit(state.copyWith(hasFinishedPlaying: true));
    });
    _positionSubscription = _audioPlayerService.position.listen(_onPosition);
    _durationSubscription = _audioPlayerService.duration.listen(_onDuration);
    if (!isPractice) unawaited(_audioPlayerService.play(_audioSource));
  }

  final AnswerOutboxDao _outboxDao;
  final AudioPlayerService _audioPlayerService;
  final String _audioSource;
  final String attemptPublicId;
  final String pinnedItemPublicId;
  late final StreamSubscription<bool> _finishedSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  Duration _lastPosition = Duration.zero;
  Duration? _lastDuration;

  Future<void> startPlayback() async {
    emit(state.copyWith(hasStartedPlaying: true));
    unawaited(_audioPlayerService.play(_audioSource));
  }

  Future<void> replayAudio() async {
    emit(state.copyWith(hasFinishedPlaying: false, progress: 0.0));
    await _audioPlayerService.replay();
  }

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
