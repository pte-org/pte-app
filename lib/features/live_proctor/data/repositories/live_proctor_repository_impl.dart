import '../../../../core/network/api_client.dart';
import '../../domain/live_proctor_types.dart';
import '../../domain/repositories/live_proctor_repository.dart';
import '../models/live_proctor_models.dart';

class LiveProctorRepositoryImpl implements LiveProctorRepository {
  LiveProctorRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<AssignedProctorSession>> loadAssignedSessions() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/scheduling/proctor-assignments/me',
    );
    return (response.data ?? const [])
        .map(
          (value) => AssignedProctorSessionModel.fromJson(
            value as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ViolationEvent>> loadViolations(String sessionPublicId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/proctor/exam-sessions/$sessionPublicId/violations',
    );
    return (response.data ?? const [])
        .map(
          (value) => ViolationEventModel.fromJson(
            value as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList(growable: false);
  }
}
