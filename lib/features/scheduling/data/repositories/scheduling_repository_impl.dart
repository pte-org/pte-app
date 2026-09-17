import '../../../../core/network/api_client.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../../domain/participant_types.dart';
import '../../domain/session_types.dart';
import '../models/session_model.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  SchedulingRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// The `/api/scheduling` prefix IS required — `pte-api/deploy/api-routes.caddy`
  /// strips it before forwarding to the monolith's bare `/sessions` mapping.
  /// `AppConfig.gatewayBaseUrl` points at that Caddy instance (`:8080`), not
  /// at the app directly (`:8091`) — every other module in this app
  /// (`/api/iam/...`, `/api/media/...`, `/api/proctor/...`, ...) keeps the
  /// same convention for the same reason. (An earlier Plan B pass removed
  /// this prefix by mistake, having missed the Caddy layer — reverted.)
  static const _sessionsPath = '/api/scheduling/sessions';
  final ApiClient _apiClient;

  @override
  Future<List<ExamSession>> loadSessions() async {
    final response = await _apiClient.get<List<dynamic>>(_sessionsPath);
    return (response.data ?? const [])
        .map(
          (item) =>
              SessionModel.fromJson(item as Map<String, dynamic>).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<ExamSession> loadSession(String publicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_sessionsPath/$publicId',
    );
    return SessionModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<ExamSession> createSession(CreateSessionInput input) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _sessionsPath,
      data: {
        'name': input.name,
        'skills': input.skills.map((skill) => skill.wireName).toList(growable: false),
        'opensAt': input.opensAt.toUtc().toIso8601String(),
        'closesAt': input.closesAt.toUtc().toIso8601String(),
      },
    );
    return SessionModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<ExamSession> openSession(String publicId) =>
      _transition(publicId, 'open');

  @override
  Future<ExamSession> closeSession(String publicId) =>
      _transition(publicId, 'close');

  Future<ExamSession> _transition(String publicId, String action) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_sessionsPath/$publicId/$action',
    );
    return SessionModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<List<AssignedClass>> loadAssignedClasses(String sessionPublicId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '$_sessionsPath/$sessionPublicId/classes',
    );
    return (response.data ?? const [])
        .map((item) => _assignedClassFromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<AssignedClass> assignClass(
    String sessionPublicId,
    String classPublicId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_sessionsPath/$sessionPublicId/classes',
      data: {'classPublicId': classPublicId},
    );
    return _assignedClassFromJson(response.data!);
  }

  @override
  Future<void> unassignClass(String sessionPublicId, String classPublicId) =>
      _apiClient.delete<void>(
        '$_sessionsPath/$sessionPublicId/classes/$classPublicId',
      );

  AssignedClass _assignedClassFromJson(Map<String, dynamic> json) =>
      AssignedClass(
        sessionPublicId: json['sessionPublicId'] as String,
        classPublicId: json['classPublicId'] as String,
      );

  @override
  Future<EnrollmentResult> enrollStudent(
    String sessionPublicId,
    String studentPublicId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_sessionsPath/$sessionPublicId/enrollments',
      data: {'studentPublicId': studentPublicId},
    );
    final data = response.data!;
    return EnrollmentResult(
      publicId: data['publicId'] as String,
      sessionPublicId: data['sessionPublicId'] as String,
      studentPublicId: data['studentPublicId'] as String,
    );
  }

  @override
  Future<ProctorAssignmentResult> assignProctor(
    String sessionPublicId,
    String proctorPublicId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_sessionsPath/$sessionPublicId/proctors',
      data: {'proctorPublicId': proctorPublicId},
    );
    final data = response.data!;
    return ProctorAssignmentResult(
      publicId: data['publicId'] as String,
      sessionPublicId: data['sessionPublicId'] as String,
      proctorPublicId: data['proctorPublicId'] as String,
    );
  }
}
