import '../../domain/session_types.dart';

sealed class SessionCreateState {
  const SessionCreateState();
}

final class SessionCreateInitial extends SessionCreateState {
  const SessionCreateInitial();
}

final class SessionCreateSubmitting extends SessionCreateState {
  const SessionCreateSubmitting();
}

final class SessionCreateInvalid extends SessionCreateState {
  const SessionCreateInvalid(this.message);
  final String message;
}

final class SessionCreateSuccess extends SessionCreateState {
  const SessionCreateSuccess(this.session);
  final ExamSession session;
}

final class SessionCreateFailure extends SessionCreateState {
  const SessionCreateFailure(this.error);
  final Object error;
}
