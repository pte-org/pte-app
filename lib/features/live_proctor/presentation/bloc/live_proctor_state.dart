import '../../domain/live_proctor_types.dart';

enum LiveProctorStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  reconnectFailed,
  failure,
}

class LiveProctorState {
  const LiveProctorState({
    this.status = LiveProctorStatus.idle,
    this.canControl = false,
    this.proctorSession,
    this.violations = const [],
    this.commandPending = false,
    this.message,
    this.reconnectAttempt = 0,
  });

  final LiveProctorStatus status;
  final bool canControl;
  final ProctorSession? proctorSession;
  final List<ViolationEvent> violations;
  final bool commandPending;
  final String? message;
  final int reconnectAttempt;

  LiveProctorState copyWith({
    LiveProctorStatus? status,
    bool? canControl,
    ProctorSession? proctorSession,
    List<ViolationEvent>? violations,
    bool? commandPending,
    String? message,
    int? reconnectAttempt,
  }) => LiveProctorState(
    status: status ?? this.status,
    canControl: canControl ?? this.canControl,
    proctorSession: proctorSession ?? this.proctorSession,
    violations: violations ?? this.violations,
    commandPending: commandPending ?? this.commandPending,
    message: message,
    reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
  );
}
