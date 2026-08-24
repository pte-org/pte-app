import '../../domain/host_audit_types.dart';

sealed class ViolationAuditState {
  const ViolationAuditState();
}

final class ViolationAuditInitial extends ViolationAuditState {
  const ViolationAuditInitial();
}

final class ViolationAuditLoading extends ViolationAuditState {
  const ViolationAuditLoading();
}

final class ViolationAuditEmpty extends ViolationAuditState {
  const ViolationAuditEmpty();
}

final class ViolationAuditLoaded extends ViolationAuditState {
  const ViolationAuditLoaded(this.items);
  final List<ViolationAuditEvent> items;
}

final class ViolationAuditFailure extends ViolationAuditState {
  const ViolationAuditFailure(this.error);
  final Object error;
}
