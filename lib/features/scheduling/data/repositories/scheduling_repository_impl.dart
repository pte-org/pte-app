import '../../../../core/network/api_client.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../../domain/session_types.dart';
import '../models/session_model.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  SchedulingRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

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
        'snapshotPublicId': input.snapshotPublicId,
        'opensAt': input.opensAt.toUtc().toIso8601String(),
        'closesAt': input.closesAt.toUtc().toIso8601String(),
      },
    );
    return SessionModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<ExamSession> setComposition(
    String publicId,
    SetCompositionInput input,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_sessionsPath/$publicId/composition',
      data: {
        'items': input.items
            .map(
              (item) => {
                'taskType': item.taskType,
                'section': item.section,
                'orderIndex': item.orderIndex,
                'timingOverrideSeconds': item.timingOverrideSeconds,
              },
            )
            .toList(growable: false),
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
  Future<List<SnapshotTaskOption>> loadSnapshotOptions(
    String snapshotPublicId,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/authoring/snapshots/$snapshotPublicId',
    );
    final items = (response.data!['items'] as List<dynamic>?) ?? const [];
    final options = <String, SnapshotTaskOption>{};
    for (final value in items) {
      final item = value as Map<String, dynamic>;
      final taskType = item['taskType'] as String;
      options.putIfAbsent(
        taskType,
        () => SnapshotTaskOption(
          taskType: taskType,
          section: item['section'] as String,
          title: item['title'] as String,
        ),
      );
    }
    return List.unmodifiable(options.values);
  }
}
