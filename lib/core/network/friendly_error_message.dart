import 'api_exceptions.dart';

/// Turns an [ApiException] into a short, human-readable sentence for a
/// `SnackBar` — the raw `'$runtimeType: $message'` from [ApiException
/// .toString] (e.g. `"ConflictException: ALREADY_ATTEMPTED"`) is a
/// diagnostic string, not something a student should have to read. Any
/// [error] that isn't an [ApiException] falls back to its own [toString],
/// unchanged — this stays scoped to the one exception hierarchy this
/// (`core/network`) layer actually owns.
String friendlyErrorMessage(Object error) {
  if (error is! ApiException) return error.toString();

  return switch (error) {
    ConflictException(:final message) when message == 'ALREADY_ATTEMPTED' =>
      "You've already used this session ID and can't restart it. Ask your host for a new session.",
    NotCurrentTaskException() => "That task isn't current anymore — refreshing to your actual current task.",
    ConflictException() => 'That action conflicts with the current state. Please try again.',
    AuthException() => 'Your session has expired or your credentials are invalid. Please log in again.',
    ForbiddenException() => "You don't have permission to do that.",
    ReplayLimitExceededException() => 'No plays left for this audio.',
    ValidationException(:final message) => message,
    RateLimitException() => 'Too many requests — please wait a moment and try again.',
    NotFoundException() => "That wasn't found. Please double-check and try again.",
    AudioUrlExpiredException() => 'That audio link expired. Please try again.',
    GoneException() => 'That resource is no longer available.',
    NetworkException() => "Couldn't reach the server. Check your connection and try again.",
    UnknownApiException(:final message) => 'Something went wrong. ($message)',
  };
}
