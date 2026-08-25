import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';

/// `GET /api/exam-delivery/attempts/{id}/timer` response shape. Carries the
/// same deadline/`serverNow` fields as `TaskView` so `TimerService` computes
/// remaining time the same way on every reconciliation as it does on the
/// initial seed — only `phase` and `currentOrderIndex` are authoritative
/// server-only additions not present on `TaskView` (phase-04 Design
/// Constraints).
class TimerStateResponse {
  const TimerStateResponse({
    required this.phase,
    required this.currentOrderIndex,
    required this.prepDeadline,
    required this.responseDeadline,
    required this.serverNow,
    this.examEndTime,
  });

  final TimerPhase phase;
  final int currentOrderIndex;
  final DateTime prepDeadline;
  final DateTime responseDeadline;
  final DateTime serverNow;

  /// Whole-attempt deadline — see `TaskView.examEndTime`. Null only for an
  /// attempt created before the backend started populating this field.
  final DateTime? examEndTime;

  factory TimerStateResponse.fromJson(Map<String, dynamic> json) {
    return TimerStateResponse(
      phase: _phaseFromWire(json['phase'] as String),
      currentOrderIndex: json['currentOrderIndex'] as int,
      prepDeadline: DateTime.parse(json['prepDeadline'] as String),
      responseDeadline: DateTime.parse(json['responseDeadline'] as String),
      serverNow: DateTime.parse(json['serverNow'] as String),
      examEndTime: json['examEndTime'] == null ? null : DateTime.parse(json['examEndTime'] as String),
    );
  }

  static TimerPhase _phaseFromWire(String value) {
    return switch (value) {
      'PREP' => TimerPhase.prep,
      'RESPONSE' => TimerPhase.response,
      _ => throw FormatException('Unknown timer phase: $value'),
    };
  }
}
