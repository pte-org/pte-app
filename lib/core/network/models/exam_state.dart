/// Skeleton DTO for the server-authoritative exam attempt state — fields
/// must be reconciled against the real `aptis-be` contract before Phase 6
/// wires this into the exam-delivery Bloc.
class ExamState {
  const ExamState({
    required this.attemptId,
    required this.currentPartId,
    required this.timeRemaining,
  });

  factory ExamState.fromJson(Map<String, dynamic> json) {
    return ExamState(
      attemptId: json['attempt_id'] as String,
      currentPartId: json['current_part_id'] as String,
      timeRemaining: Duration(seconds: json['time_remaining_seconds'] as int),
    );
  }

  final String attemptId;
  final String currentPartId;
  final Duration timeRemaining;
}
