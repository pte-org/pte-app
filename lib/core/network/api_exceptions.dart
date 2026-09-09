/// Typed exception hierarchy for `ApiClient`. Every error-mapping call site
/// in this app (Phase 2's `SyncEngine`, Phase 6's `MediaUploadCoordinator`,
/// Phase 7's typed-409 dispatch) branches on these types, never on a raw
/// status code — keep new causes here, not as private details of one
/// feature.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 401 — authentication itself failed (bad credentials, revoked
/// session). Distinct from a token needing refresh, which the
/// `TokenRefreshInterceptor` handles transparently before this is ever
/// thrown to a caller.
final class AuthException extends ApiException {
  const AuthException(super.message);
}

/// The caller is authenticated but lacks permission for this operation.
/// Keeping 403 separate prevents role gates from becoming false logouts.
final class ForbiddenException extends ApiException {
  const ForbiddenException(super.message);
}

/// 400/422 — request payload rejected by the server.
final class ValidationException extends ApiException {
  const ValidationException(super.message);
}

/// 429 — Redis token-bucket rate limit (20/s burst 40). Distinct from
/// `AuthException`/`ValidationException` per FR-11 so callers can
/// backoff-and-retry instead of treating it as a hard failure.
/// [retryAfter], when the server/gateway supplies a `Retry-After` header,
/// is the authoritative cooldown; callers fall back to their own
/// exponential backoff when it's `null` (phase-07 Design Constraints).
final class RateLimitException extends ApiException {
  const RateLimitException(super.message, {this.retryAfter});

  final Duration? retryAfter;
}

/// 409 — a conflict the server considers final on the answers endpoint
/// (stale/non-current task, or an already-submitted answer). A generic 409
/// with no recognized `message` body (including `ANSWER_ALREADY_SUBMITTED`)
/// stays this type and is still treated as terminal — the conservative
/// fallback Phase 2 established. [NotCurrentTaskException] is the one cause
/// precise enough to warrant its own type (phase-02/07 Design Constraints;
/// a former `ResponseWindowExpiredException` sibling was removed in
/// client-side-exam-timer Phase 7 once the server-side exception producing
/// it was deleted in Phase 5); `base` (not `final`) so a typed cause can
/// extend it while [ApiException]'s own sealed exhaustiveness only needs to
/// know about this type, not every conflict subclass. [message] carries the
/// response body's distinguishing `message` field for diagnostics.
base class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// A submission targeted an item that isn't the attempt's current task —
/// `pte-api`'s `NotCurrentTaskException` (`message: "NOT_CURRENT_TASK"`).
/// The local outbox row is terminal; the client's view of "current task" is
/// stale and must re-fetch `next-task` (phase-07 Design Constraints).
final class NotCurrentTaskException extends ConflictException {
  const NotCurrentTaskException(super.message);
}

/// The attempt reached a terminal status before some other call did —
/// `pte-api`'s `AttemptAlreadyCompleteException` (`message: "ATTEMPT_ALREADY_COMPLETE"`),
/// thrown by several endpoints (`submitAnswer`, `playAudio`, `forceSubmit`, `heartbeat`)
/// whenever the attempt is no longer `IN_PROGRESS`. Distinct from the generic
/// [ConflictException] fallback so a caller can stop retrying/polling outright instead
/// of retrying a call that can now never succeed (plans/phat-speaking-dynamic-prep-timing
/// follow-up; the specific "`TimerService._poll`" caller that comment originally named
/// no longer exists — `TimerService` stopped polling entirely in client-side-exam-timer
/// Phase 3 — but the same reasoning applies to every other caller of this exception).
final class AttemptAlreadyCompleteException extends ConflictException {
  const AttemptAlreadyCompleteException(super.message);
}

/// `/audio`'s per-item play-count limit was already reached — `pte-api`'s
/// `ReplayLimitExceededException` (403, `message: "REPLAY_LIMIT_EXCEEDED"`).
/// Deliberately not a subtype of [ForbiddenException] (that type is `final`,
/// and a genuine permission failure elsewhere in the app has nothing to do
/// with this one endpoint's play-count semantics) — callers who want to
/// show "no plays left" catch this specifically; anyone who doesn't still
/// catches the sealed [ApiException] (plans/phat-speaking-audio-prompt-e2e).
final class ReplayLimitExceededException extends ApiException {
  const ReplayLimitExceededException(super.message);
}

/// `/audio`'s resolved URL's TTL has passed — `pte-api`'s
/// `AudioUrlExpiredException` (410, `message: "AUDIO_URL_EXPIRED"`). Should
/// not happen under normal operation (the TTL spans the whole session
/// window), so callers can treat this as an unexpected-but-non-crashing
/// condition rather than a routine retry case
/// (plans/phat-speaking-audio-prompt-e2e).
final class AudioUrlExpiredException extends ApiException {
  const AudioUrlExpiredException(super.message);
}

/// 410 — the resource existed but is now permanently gone. Currently only
/// produced by `/audio`'s TTL expiry before endpoint-specific remapping
/// (see `ApiClient.playAudio`) turns it into [AudioUrlExpiredException].
final class GoneException extends ApiException {
  const GoneException(super.message);
}

/// 404 — the resource genuinely doesn't exist *or* exists but isn't visible
/// to the caller yet, indistinguishably (e.g. `pte-api`'s reporting
/// endpoint returns the same `REPORT_NOT_FOUND` 404 for both "not yet
/// published" and "not owned" — phase-08 Design Constraints). Callers for
/// whom 404 is an expected steady state (not a failure) branch on this type
/// specifically rather than falling through to [UnknownApiException].
final class NotFoundException extends ApiException {
  const NotFoundException(super.message);
}

/// No response reached the server at all (DNS, connection refused,
/// timeout) — as opposed to [ApiException]'s "server responded with an
/// error status."
final class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// Catch-all for a server error response that doesn't map to a more
/// specific type above (5xx, or an unrecognized 4xx).
final class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}
