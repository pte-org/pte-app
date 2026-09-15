import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/dev/mock_backend/mock_live_proctor_transport.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_transport.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_types.dart';

void main() {
  test(
    'a controlling proctor connects, gets a session, and sees flags and commands echoed',
    () async {
      final transport = MockLiveProctorTransport(
        latency: Duration.zero,
        violationInterval: const Duration(hours: 1),
      );
      final events = <LiveTransportEvent>[];
      final subscription = transport.events.listen(events.add);

      await transport.connect(
        accessToken: 'token',
        sessionPublicId: 'mock-full-exam',
        canControl: true,
      );
      transport.flagViolation(
        proctorSessionPublicId: 'mock-proctor-session-mock-full-exam',
        attemptPublicId: 'attempt-1',
        violationType: ViolationType.other,
      );
      transport.issueCommand(
        proctorSessionPublicId: 'mock-proctor-session-mock-full-exam',
        attemptPublicId: 'attempt-1',
        commandType: ProctorCommandType.forceSubmit,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await transport.disconnect();
      await subscription.cancel();

      expect(events.map((event) => event.runtimeType), [
        LiveTransportConnected,
        LiveProctorSessionOpened,
        LiveViolationReceived,
        LiveCommandAccepted,
      ]);
      final flagged = (events[2] as LiveViolationReceived).violation;
      expect(flagged.type, ViolationType.other);
      expect(flagged.detail, 'Flagged by proctor');
    },
  );

  test('an observer connects without opening a proctor session', () async {
    final transport = MockLiveProctorTransport(
      latency: Duration.zero,
      violationInterval: const Duration(hours: 1),
    );
    final events = <LiveTransportEvent>[];
    final subscription = transport.events.listen(events.add);

    await transport.connect(
      accessToken: 'token',
      sessionPublicId: 'mock-full-exam',
      canControl: false,
    );
    await Future<void>.delayed(Duration.zero);
    await transport.disconnect();
    await subscription.cancel();

    expect(events.single, isA<LiveTransportConnected>());
  });
}
