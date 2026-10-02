import 'dart:async';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/domain/answer_payload_parser.dart';
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
    String? initialPayload,
    bool isPractice = false,
  }) : _outboxDao = outboxDao,
       _audioPlayerService = audioPlayerService,
       _audioSource = audioSource,
       super(
         McListeningSingleState(
           selectedOrderIndex: singleSelectionFromAnswerPayload(initialPayload),
           hasStartedPlaying: !isPractice,
         ),
         answerChanged:
             (McListeningSingleState current, McListeningSingleState initial) =>
                 current.selectedOrderIndex != initial.selectedOrderIndex,
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
