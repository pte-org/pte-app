sealed class SessionDetailEvent {
  const SessionDetailEvent();
}

final class SessionDetailRequested extends SessionDetailEvent {
  const SessionDetailRequested(this.publicId);
  final String publicId;
}

final class SessionOpenRequested extends SessionDetailEvent {
  const SessionOpenRequested();
}

final class SessionCloseRequested extends SessionDetailEvent {
  const SessionCloseRequested();
}

final class ClassAssignRequested extends SessionDetailEvent {
  const ClassAssignRequested(this.classPublicId);
  final String classPublicId;
}

final class ClassUnassignRequested extends SessionDetailEvent {
  const ClassUnassignRequested(this.classPublicId);
  final String classPublicId;
}
