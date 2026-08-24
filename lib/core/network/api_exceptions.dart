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
/// (stale/non-current task, expired response window, or an
/// already-submitted answer). A generic 409 with no recognized `message`
/// body (including `ANSWER_ALREADY_SUBMITTED`) stays this type and is
/// still treated as terminal — the conservative fallback Phase 2
/// established. [NotCurrentTaskException] and [ResponseWindowExpiredException]
/// are the two causes precise enough to warrant their own type (phase-02/07
/// Design Constraints); `base` (not `final`) so they can extend it while
/// [ApiException]'s own sealed exhaustiveness only needs to know about this
/// type, not every conflict subclass. [message] carries the response
/// body's distinguishing `message` field for diagnostics.
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

/// A submission arrived after the server-computed response deadline —
/// `pte-api`'s `ResponseWindowExpiredException`
/// (`message: "RESPONSE_WINDOW_EXPIRED"`). Same terminal-and-refetch
/// handling as [NotCurrentTaskException] (phase-07 Design Constraints).
final class ResponseWindowExpiredException extends ConflictException {
  const ResponseWindowExpiredException(super.message);
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
