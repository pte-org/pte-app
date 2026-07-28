import 'live_proctor_types.dart';

sealed class LiveTransportEvent {
  const LiveTransportEvent();
}

final class LiveTransportConnected extends LiveTransportEvent {
  const LiveTransportConnected();
}

final class LiveTransportDisconnected extends LiveTransportEvent {
  const LiveTransportDisconnected([this.error]);

  final Object? error;
}

final class LiveProctorSessionOpened extends LiveTransportEvent {
  const LiveProctorSessionOpened(this.session);

  final ProctorSession session;
}

final class LiveViolationReceived extends LiveTransportEvent {
  const LiveViolationReceived(this.violation);

  final ViolationEvent violation;
}

final class LiveCommandAccepted extends LiveTransportEvent {
  const LiveCommandAccepted(this.attemptPublicId);

  final String attemptPublicId;
}

final class LiveTransportFailure extends LiveTransportEvent {
  const LiveTransportFailure(this.error);

  final Object error;
}

abstract interface class LiveProctorTransport {
  Stream<LiveTransportEvent> get events;

  Future<void> connect({
    required String accessToken,
    required String sessionPublicId,
    required bool canControl,
  });

  Future<void> disconnect();

  void issueCommand({
    required String proctorSessionPublicId,
    required String attemptPublicId,
    required ProctorCommandType commandType,
    int? extraSeconds,
  });

  void flagViolation({
    required String proctorSessionPublicId,
    required String attemptPublicId,
    required ViolationType violationType,
    String? detail,
  });
}
