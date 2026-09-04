import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/timer_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_state_response.dart';

class TimerRepositoryImpl implements TimerRepository {
  TimerRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<TimerStateResponse> fetchTimerState(String attemptPublicId) async {
    // Routed through ApiClient's own dedicated method (not the generic
    // get()) so a 409 comes back as the typed AttemptAlreadyCompleteException
    // rather than a bare ConflictException (plans/phat-speaking-dynamic-
    // prep-timing follow-up).
    final response = await _apiClient.fetchTimerState(attemptPublicId);
    return TimerStateResponse.fromJson(response.data!);
  }
}
