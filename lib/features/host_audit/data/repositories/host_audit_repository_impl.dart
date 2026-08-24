import '../../../../core/network/api_client.dart';
import '../../domain/host_audit_types.dart';
import '../../domain/repositories/host_audit_repository.dart';
import '../models/host_audit_models.dart';

class HostAuditRepositoryImpl implements HostAuditRepository {
  HostAuditRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<NotificationAudit>> loadNotifications() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/notification/notifications',
    );
    return (response.data ?? const [])
        .map(
          (value) => NotificationAuditModel.fromJson(
            value as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ViolationAuditEvent>> loadViolations(
    String sessionPublicId,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/proctor/exam-sessions/$sessionPublicId/violations',
    );
    return (response.data ?? const [])
        .map(
          (value) => ViolationAuditModel.fromJson(
            value as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList(growable: false);
  }
}
