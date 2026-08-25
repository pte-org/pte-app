/// Thin seam over `just_audio`, scoped to the device-check feature only —
/// deliberately separate from `AudioPlayerService`
/// (`lib/features/exam_attempt/listening/domain/audio_player_service.dart`),
/// which is asset-only by design (its own doc comment: "the asset-vs-remote
/// distinction stays inside this file, never leaks to callers") and is used
/// by real production Listening tasks. This feature needs BOTH a local
/// file path (the candidate's own just-recorded voice clip) and a bundled
/// asset (the fixed sound-test clip), so it gets its own small abstraction
/// rather than widening that shared, already-narrow contract.
abstract class DeviceCheckAudioPlayer {
  /// Plays a local file — e.g. the candidate's own recording, written to
  /// the temp directory by `AudioRecorderService`.
  Future<void> playFile(String filePath);

  /// Plays a bundled Flutter asset — e.g. the fixed sound-test clip.
  Future<void> playAsset(String assetPath);

  /// Emits `true` exactly once, when the current/most recent playback
  /// (from either [playFile] or [playAsset]) reaches its end — same
  /// completion-signal shape as `AudioPlayerService.hasFinishedPlaying`.
  Stream<bool> get hasFinishedPlaying;

  Future<void> close();
}
