import '../host_audit_types.dart';

abstract interface class HostAuditRepository {
  Future<List<NotificationAudit>> loadNotifications();

  Future<ViolationAuditPageData> loadViolationPage(
    String sessionPublicId, {
    String? cursor,
  });

  Future<List<ViolationAuditEvent>> loadViolations(String sessionPublicId);
}
