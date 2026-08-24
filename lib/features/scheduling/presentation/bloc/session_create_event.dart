import '../../domain/session_types.dart';

sealed class SessionCreateEvent {
  const SessionCreateEvent();
}

final class SessionCreateSubmitted extends SessionCreateEvent {
  const SessionCreateSubmitted(this.input);
  final CreateSessionInput input;
}
