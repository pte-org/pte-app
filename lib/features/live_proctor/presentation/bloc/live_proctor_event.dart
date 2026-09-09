import '../../domain/live_proctor_transport.dart';
import '../../domain/live_proctor_types.dart';

sealed class LiveProctorEvent {
  const LiveProctorEvent();
}

final class LiveProctorStarted extends LiveProctorEvent {
  const LiveProctorStarted({
    required this.sessionPublicId,
    required this.canControl,
  });

  final String sessionPublicId;
  final bool canControl;
}

final class ProctorCommandRequested extends LiveProctorEvent {
  const ProctorCommandRequested({
    required this.attemptPublicId,
    required this.commandType,
  });

  final String attemptPublicId;
  final ProctorCommandType commandType;
}

final class ViolationFlagRequested extends LiveProctorEvent {
  const ViolationFlagRequested({
    required this.attemptPublicId,
    required this.violationType,
    this.detail,
  });

  final String attemptPublicId;
  final ViolationType violationType;
  final String? detail;
}

final class LiveReconnectRequested extends LiveProctorEvent {
  const LiveReconnectRequested();
}

final class LiveProctorStopped extends LiveProctorEvent {
  const LiveProctorStopped();
}

final class LiveTransportEventReceived extends LiveProctorEvent {
  const LiveTransportEventReceived(this.event);

  final LiveTransportEvent event;
}
