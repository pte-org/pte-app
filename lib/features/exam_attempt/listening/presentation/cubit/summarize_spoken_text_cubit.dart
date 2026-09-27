import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/listening_payload.dart';
import 'package:pte_app/features/exam_attempt/domain/word_count.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/summarize_spoken_text_state.dart';

/// Same discrete-input, no-debounce shape as `WriteFromDictationCubit`
/// (phase-02 Design Constraints) — kept as a separate class rather than a
/// shared generic, matching this codebase's existing per-type duplication
/// convention (e.g. `McReadingSingleCubit`/`McReadingMultipleCubit`).
class SummarizeSpokenTextCubit
    extends TaskAnswerCubit<SummarizeSpokenTextState> {
  SummarizeSpokenTextCubit({
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
         SummarizeSpokenTextState(
           draftText: initialPayload ?? '',
           wordCount: countWords(initialPayload ?? ''),
           hasStartedPlaying: !isPractice,
         ),
         answerChanged:
             (
               SummarizeSpokenTextState current,
               SummarizeSpokenTextState initial,
             ) => current.draftText != initial.draftText,
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

  void draftChanged(String text) {
    emit(state.copyWith(draftText: text, wordCount: countWords(text)));
    unawaited(_persist());
  }

  Future<void> _persist() {
    return _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: listeningFreeTextPayload(state.draftText),
    );
  }

  /// Every keystroke already writes synchronously, but if the student never
  /// types anything at all (client-side-exam-timer Phase 4), `_persist()`
  /// has never been called — call it unconditionally so `SyncEngine.flushOne`
  /// always has a row to submit, matching `McReadingSingleCubit`'s fallback.
  @override
  Future<void> flushPendingEdit() => _persist();

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
