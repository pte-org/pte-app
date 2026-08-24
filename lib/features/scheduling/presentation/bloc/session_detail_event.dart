import '../../domain/session_types.dart';

sealed class SessionDetailEvent {
  const SessionDetailEvent();
}

final class SessionDetailRequested extends SessionDetailEvent {
  const SessionDetailRequested(this.publicId);
  final String publicId;
}

final class SessionCompositionSubmitted extends SessionDetailEvent {
  const SessionCompositionSubmitted(this.input);
  final SetCompositionInput input;
}

final class SessionOpenRequested extends SessionDetailEvent {
  const SessionOpenRequested();
}

final class SessionCloseRequested extends SessionDetailEvent {
  const SessionCloseRequested();
}
