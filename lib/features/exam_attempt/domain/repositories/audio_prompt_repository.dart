/// On-demand audio-prompt playback only — kept separate from
/// `ExamAttemptRepository` (attempt lifecycle) for the same reason a
/// separate `SyncEngine`/`TimerService` exist: a distinct concern with its
/// own retry/idempotency semantics (plans/phat-speaking-audio-prompt-e2e).
abstract class AudioPromptRepository {
  /// Resolves and returns the playable URL for the given pinned item's
  /// audio prompt, subject to the server's play-count/expiry enforcement.
  /// [playRequestId] must be a fresh UUID per play attempt (idempotent
  /// retries of the *same* id replay the prior outcome instead of
  /// re-incrementing the server's play count).
  Future<String> playAudio({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String playRequestId,
  });
}
