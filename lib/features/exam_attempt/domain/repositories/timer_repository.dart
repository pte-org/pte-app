import '../timer_state_response.dart';

/// Timer resync only — kept separate from `ExamAttemptRepository` since
/// polling cadence/retry semantics are `TimerService`'s concern, not the
/// attempt lifecycle's (phase-04 Design Constraints).
abstract class TimerRepository {
  Future<TimerStateResponse> fetchTimerState(String attemptPublicId);
}
