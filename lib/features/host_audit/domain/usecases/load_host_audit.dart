import '../host_audit_types.dart';
import '../repositories/host_audit_repository.dart';

class LoadNotifications {
  const LoadNotifications({required HostAuditRepository repository})
    : _repository = repository;

  final HostAuditRepository _repository;

  Future<List<NotificationAudit>> call() => _repository.loadNotifications();
}

class LoadViolations {
  const LoadViolations({required HostAuditRepository repository})
    : _repository = repository;

  final HostAuditRepository _repository;

  Future<List<ViolationAuditEvent>> call(String sessionPublicId) =>
      _repository.loadViolations(sessionPublicId);
}
