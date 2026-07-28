import '../../domain/live_proctor_types.dart';

sealed class AssignedSessionsState {
  const AssignedSessionsState();
}

final class AssignedSessionsInitial extends AssignedSessionsState {
  const AssignedSessionsInitial();
}

final class AssignedSessionsLoading extends AssignedSessionsState {
  const AssignedSessionsLoading();
}

final class AssignedSessionsEmpty extends AssignedSessionsState {
  const AssignedSessionsEmpty();
}

final class AssignedSessionsLoaded extends AssignedSessionsState {
  const AssignedSessionsLoaded(this.sessions);

  final List<AssignedProctorSession> sessions;
}

final class AssignedSessionsFailure extends AssignedSessionsState {
  const AssignedSessionsFailure(this.error);

  final Object error;
}
