sealed class ViolationAuditBlocEvent {
  const ViolationAuditBlocEvent();
}

final class ViolationAuditRequested extends ViolationAuditBlocEvent {
  const ViolationAuditRequested(this.sessionPublicId);
  final String sessionPublicId;
}
