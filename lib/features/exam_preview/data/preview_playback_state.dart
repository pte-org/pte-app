enum PreviewPlaybackPhase {
  idle,
  loading,
  playing,
  paused,
  stopped,
  completed,
  failed,
}

class PreviewPlaybackState {
  const PreviewPlaybackState({
    this.phase = PreviewPlaybackPhase.idle,
    this.position = Duration.zero,
    this.duration,
  });

  final PreviewPlaybackPhase phase;
  final Duration position;
  final Duration? duration;

  double get progress {
    if (phase == PreviewPlaybackPhase.completed) return 1;
    final total = duration?.inMilliseconds ?? 0;
    return total <= 0 ? 0 : (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  PreviewPlaybackState copyWith({
    PreviewPlaybackPhase? phase,
    Duration? position,
    Duration? duration,
  }) => PreviewPlaybackState(
    phase: phase ?? this.phase,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );
}
