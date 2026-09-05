/// Thin seam over `just_audio` — deliberately exposes no seek/pause/replay
/// so no caller can trigger a second playback (phase-01 Design
/// Constraints). Today's [AudioPlayerServiceImpl] plays [play]'s bundled
/// Flutter asset from a fixed set of mock-data callers (Listening screens).
///
/// [playUrl] was added alongside [play] rather than reinterpreting its
/// already-opaque [source] parameter — the original design here anticipated
/// a single swappable impl ("future remote impl swaps in via GetIt alone"),
/// but Speaking's audio-prompt playback needs real network URLs while
/// Listening's existing mock-data callers still need [play]'s asset-path
/// behavior at the same time, so both coexist on one impl instead
/// (plans/phat-speaking-audio-prompt-e2e).
abstract class AudioPlayerService {
  /// Starts playback of [source]. Callers await this only to know playback
  /// has started, not finished — listen to [hasFinishedPlaying] for
  /// completion.
  Future<void> play(String source);

  /// Starts playback of the real network audio at [url] — distinct from
  /// [play]'s bundled-asset path. Same await/completion contract as [play].
  Future<void> playUrl(String url);

  /// Emits the current playback position while a [playUrl] playback is
  /// active — drives real-time progress display. Not populated for [play]
  /// (asset-based) playback, which has no progress-display need today.
  Stream<Duration> get position;

  /// Emits the current playback's total duration once known — `null` while
  /// still resolving (e.g. buffering a network URL). Paired with [position]
  /// to compute a progress fraction.
  Stream<Duration?> get duration;

  /// Emits `true` exactly once, when the current/most recent playback
  /// reaches its end. Cubits use this to flip a screen's "locked, already
  /// played" state.
  Stream<bool> get hasFinishedPlaying;

  Future<void> close();
}
