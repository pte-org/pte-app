/// Thin seam over `just_audio` — deliberately exposes no seek/pause/replay
/// so no caller can trigger a second playback (phase-01 Design
/// Constraints). Today's [AudioPlayerServiceImpl] plays from a bundled
/// Flutter asset; a future remote (presigned-URL) impl swaps in via GetIt
/// registration alone — [source] is opaque to every caller.
abstract class AudioPlayerService {
  /// Starts playback of [source]. Callers await this only to know playback
  /// has started, not finished — listen to [hasFinishedPlaying] for
  /// completion.
  Future<void> play(String source);

  /// Emits `true` exactly once, when the current/most recent playback
  /// reaches its end. Cubits use this to flip a screen's "locked, already
  /// played" state.
  Stream<bool> get hasFinishedPlaying;

  Future<void> close();
}
