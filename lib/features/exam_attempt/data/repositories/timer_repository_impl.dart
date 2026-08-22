import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/timer_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_state_response.dart';

class TimerRepositoryImpl implements TimerRepository {
  TimerRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<TimerStateResponse> fetchTimerState(String attemptPublicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/exam-delivery/attempts/$attemptPublicId/timer',
    );
    return TimerStateResponse.fromJson(response.data!);
  }
}
