/// Skeleton DTO — field names/types must be reconciled against the real
/// `aptis-be` `/exam/{attemptId}/sync-timer` contract before Phase 4 wires
/// reconciliation logic to it (see plan.md risk: "no documented field
/// contract yet").
class TimerSyncResponse {
  const TimerSyncResponse({
    required this.timeRemaining,
    required this.serverTimestamp,
  });

  factory TimerSyncResponse.fromJson(Map<String, dynamic> json) {
    return TimerSyncResponse(
      timeRemaining: Duration(seconds: json['time_remaining_seconds'] as int),
      serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
    );
  }

  final Duration timeRemaining;
  final DateTime serverTimestamp;
}
