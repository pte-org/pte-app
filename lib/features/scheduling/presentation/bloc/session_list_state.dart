import '../../domain/session_types.dart';

sealed class SessionListState {
  const SessionListState();
}

final class SessionListInitial extends SessionListState {
  const SessionListInitial();
}

final class SessionListLoading extends SessionListState {
  const SessionListLoading();
}

final class SessionListEmpty extends SessionListState {
  const SessionListEmpty();
}

final class SessionListLoaded extends SessionListState {
  const SessionListLoaded(this.sessions);
  final List<ExamSession> sessions;
}

final class SessionListFailure extends SessionListState {
  const SessionListFailure(this.error);
  final Object error;
}
