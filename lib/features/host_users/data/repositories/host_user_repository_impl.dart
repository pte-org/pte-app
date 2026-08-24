import '../../../../core/network/api_client.dart';
import '../../domain/host_user.dart';
import '../../domain/repositories/host_user_repository.dart';
import '../models/host_user_model.dart';

class HostUserRepositoryImpl implements HostUserRepository {
  const HostUserRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<HostUser>> loadUsers() async {
    final response = await _apiClient.get<List<dynamic>>('/api/iam/users');
    return (response.data ?? const [])
        .map(
          (item) =>
              HostUserModel.fromJson(item as Map<String, dynamic>).toEntity(),
        )
        .toList(growable: false);
  }
}
