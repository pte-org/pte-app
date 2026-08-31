import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_prompt_sub_stage.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';

/// Owns the one-shot "enter Playing sub-stage → call the on-demand `/audio`
/// endpoint → play the resolved URL → track real playback position" flow
/// shared by every Speaking screen with an audio prompt (Repeat Sentence,
/// Retell Lecture, Answer Short Question, Summarize Group Discussion,
/// Respond to a Situation). Sibling to `AutoRecordCubit`, not merged into
/// it: recording and audio-prompt playback are independent concerns with
/// independent trigger conditions (response-phase entry vs. Playing-
/// sub-stage entry) (plans/phat-speaking-audio-prompt-e2e).
class AudioPromptCubit extends Cubit<AudioPromptPlaybackState> {
  AudioPromptCubit({
    required AudioPromptRepository repository,
    required AudioPlayerService player,
    required this.task,
    required this.attemptPublicId,
    required this.preListenSeconds,
    required this.preRecordSeconds,
    Logger? logger,
  }) : _repository = repository,
       _player = player,
       _logger = logger ?? Logger(),
       super(const AudioPromptPlaybackState()) {
    _positionSubscription = _player.position.listen(_onPosition);
    _durationSubscription = _player.duration.listen(_onDuration);
  }

  final AudioPromptRepository _repository;
  final AudioPlayerService _player;
  final Logger _logger;
  final TaskView task;
  final String attemptPublicId;
  final int preListenSeconds;
  final int preRecordSeconds;

  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;

  Duration _lastPosition = Duration.zero;
  Duration? _lastDuration;

  /// Guards the one-shot trigger — same checked-and-set-synchronously
  /// pattern as `AutoRecordCubit._startInFlight` (the caller may forward
  /// every ~1s tick, so this must be idempotent past the first real
  /// transition; also the concrete choice behind Phase 2's "fresh
  /// X-Play-Request-Id once per Playing sub-stage entry" decision — this
  /// guard is what makes it "once").
  bool _triggered = false;

  /// Auto-triggers the `/audio` call+play purely from a forwarded
  /// [TimerSnapshot] and this cubit's own trigger guard — never derives its
  /// own deadline; `TimerService` stays the single authoritative clock
  /// (same design constraint as `AutoRecordCubit.onTimerSnapshot`). A no-op
  /// when [TaskView.audioPromptRef] is absent.
  void onTimerSnapshot(TimerSnapshot snapshot) {
    if (task.audioPromptRef == null) return;
    if (_triggered) return;
    if (!isAudioPlayingSubStage(
      task,
      snapshot,
      preListenSeconds: preListenSeconds,
      preRecordSeconds: preRecordSeconds,
    )) {
      return;
    }
    _triggered = true;
    unawaited(_play());
  }

  Future<void> _play() async {
    emit(state.copyWith(phase: AudioPromptPlaybackPhase.loading));
    try {
      final url = await _repository.playAudio(
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        playRequestId: _generatePlayRequestId(),
      );
      await _player.playUrl(url);
      emit(state.copyWith(phase: AudioPromptPlaybackPhase.playing));
    } on ReplayLimitExceededException catch (e, stackTrace) {
      _logger.w(
        'Audio prompt play rejected: replay limit exceeded',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          phase: AudioPromptPlaybackPhase.error,
          errorMessage: SpeakingWritingStrings.audioPromptReplayLimitExceededMessage,
        ),
      );
    } on AudioUrlExpiredException catch (e, stackTrace) {
      _logger.w('Audio prompt play rejected: URL expired', error: e, stackTrace: stackTrace);
      emit(
        state.copyWith(
          phase: AudioPromptPlaybackPhase.error,
          errorMessage: SpeakingWritingStrings.audioPromptUrlExpiredMessage,
        ),
      );
    } catch (e, stackTrace) {
      // Any other failure (network, unreachable file, an ApiException
      // subtype not specifically handled above) degrades to the same
      // non-crashing error state — never rethrown. Playback failures must
      // never crash the screen; the candidate can still record and submit
      // once the response phase starts regardless of this state.
      _logger.w('Audio prompt play failed', error: e, stackTrace: stackTrace);
      emit(
        state.copyWith(
          phase: AudioPromptPlaybackPhase.error,
          errorMessage: SpeakingWritingStrings.audioPromptGenericErrorMessage,
        ),
      );
    }
  }

  void _onPosition(Duration position) {
    _lastPosition = position;
    _emitProgress();
  }

  void _onDuration(Duration? duration) {
    _lastDuration = duration;
    _emitProgress();
  }

  /// Recomputed on every position/duration tick while [state.phase] is
  /// `playing` — held at 0.0 whenever duration is still unresolved (e.g.
  /// buffering), never divides by an unknown/zero duration.
  void _emitProgress() {
    if (state.phase != AudioPromptPlaybackPhase.playing) return;
    final duration = _lastDuration;
    final progress = (duration == null || duration <= Duration.zero)
        ? 0.0
        : (_lastPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    emit(state.copyWith(progress: progress));
  }

  /// Server treats this as an opaque idempotency key, not a validated UUID
  /// (`AttemptController.playAudio`'s `X-Play-Request-Id` is a plain
  /// `String`) — a timestamp+random suffix is sufficiently unique without
  /// adding a `uuid` package dependency for one call site.
  String _generatePlayRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '$timestamp-$suffix';
  }

  @override
  Future<void> close() async {
    unawaited(_positionSubscription.cancel());
    unawaited(_durationSubscription.cancel());
    await _player.close();
    return super.close();
  }
}
