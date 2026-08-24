import '../../domain/host_audit_types.dart';

sealed class NotificationAuditState {
  const NotificationAuditState();
}

final class NotificationAuditInitial extends NotificationAuditState {
  const NotificationAuditInitial();
}

final class NotificationAuditLoading extends NotificationAuditState {
  const NotificationAuditLoading();
}

final class NotificationAuditEmpty extends NotificationAuditState {
  const NotificationAuditEmpty();
}

final class NotificationAuditLoaded extends NotificationAuditState {
  const NotificationAuditLoaded(this.items);
  final List<NotificationAudit> items;
}

final class NotificationAuditFailure extends NotificationAuditState {
  const NotificationAuditFailure(this.error);
  final Object error;
}
