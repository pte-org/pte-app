import '../host_audit_types.dart';

abstract interface class HostAuditRepository {
  Future<List<NotificationAudit>> loadNotifications();

  Future<List<ViolationAuditEvent>> loadViolations(String sessionPublicId);
}
