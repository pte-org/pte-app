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

/// 401/403 — authentication itself failed (bad credentials, revoked
/// session). Distinct from a token needing refresh, which the
/// `TokenRefreshInterceptor` handles transparently before this is ever
/// thrown to a caller.
final class AuthException extends ApiException {
  const AuthException(super.message);
}

/// 400/422 — request payload rejected by the server.
final class ValidationException extends ApiException {
  const ValidationException(super.message);
}

/// 429 — Redis token-bucket rate limit (20/s burst 40). Distinct from
/// `AuthException`/`ValidationException` per FR-11 so callers can
/// backoff-and-retry instead of treating it as a hard failure.
final class RateLimitException extends ApiException {
  const RateLimitException(super.message);
}

/// 409 — a conflict the server considers final on the answers endpoint
/// (stale/non-current task, expired response window, or an
/// already-submitted answer). Phase 2 maps every 409 here to
/// `terminalRejected` as a conservative-but-correct heuristic, since all
/// three currently-known causes are in fact terminal; Phase 7 replaces
/// this with precise type-dispatch once typed subclasses exist for each
/// cause (phase-02 Design Constraints). [message] carries the response
/// body's distinguishing `message` field for diagnostics.
final class ConflictException extends ApiException {
  const ConflictException(super.message);
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
