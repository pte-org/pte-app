import 'package:equatable/equatable.dart';

/// Mirrors [AutoRecordState]'s enum-phase-plus-fields shape for the same
/// reason: none of this task's playback mechanics differ across the 5
/// audio-prompt Speaking screens that share [AudioPromptCubit]
/// (plans/phat-speaking-audio-prompt-e2e).
enum AudioPromptPlaybackPhase { idle, loading, playing, error }

class AudioPromptPlaybackState extends Equatable {
  const AudioPromptPlaybackState({
    this.phase = AudioPromptPlaybackPhase.idle,
    this.progress = 0.0,
    this.errorMessage,
  });

  final AudioPromptPlaybackPhase phase;

  /// 0.0–1.0 fraction of the current playback's real position/duration.
  /// Held at 0.0 whenever [phase] isn't `playing` or duration is still
  /// unresolved (e.g. buffering) — never divides by an unknown/zero
  /// duration.
  final double progress;

  /// Set only when [phase] is `error` — a short, user-facing reason
  /// ("no plays left", "link expired", or a generic fallback), never the
  /// raw exception text.
  final String? errorMessage;

  AudioPromptPlaybackState copyWith({
    AudioPromptPlaybackPhase? phase,
    double? progress,
    String? errorMessage,
  }) {
    return AudioPromptPlaybackState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [phase, progress, errorMessage];
}
