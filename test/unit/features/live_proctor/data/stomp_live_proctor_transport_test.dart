import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:pte_app/features/live_proctor/data/transport/stomp_live_proctor_transport.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_transport.dart';

class _MockStompClient extends Mock implements StompClient {}

void main() {
  late _MockStompClient client;
  late StompConfig config;
  late StompLiveProctorTransport transport;

  setUp(() {
    client = _MockStompClient();
    when(client.activate).thenReturn(null);
    when(client.deactivate).thenReturn(null);
    when(
      () => client.subscribe(
        destination: any(named: 'destination'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(({Map<String, String>? unsubscribeHeaders}) {});
    when(
      () => client.send(
        destination: any(named: 'destination'),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenReturn(null);
    transport = StompLiveProctorTransport(
      clientFactory: (value) {
        config = value;
        return client;
      },
    );
  });

  test(
    'authenticates CONNECT, subscribes first, then opens proctor session',
    () async {
      final events = <LiveTransportEvent>[];
      final subscription = transport.events.listen(events.add);
      addTearDown(subscription.cancel);

      await transport.connect(
        accessToken: 'jwt',
        sessionPublicId: 'session-1',
        canControl: true,
      );
      config.onConnect(StompFrame(command: 'CONNECTED'));
      await Future<void>.delayed(Duration.zero);

      expect(config.url, 'ws://localhost:8080/api/proctor/ws');
      expect(config.stompConnectHeaders?['Authorization'], 'Bearer jwt');
      verify(
        () => client.subscribe(
          destination: '/topic/proctor-sessions/session-1',
          callback: any(named: 'callback'),
        ),
      ).called(1);
      verify(
        () => client.subscribe(
          destination: '/user/queue/proctor-session',
          callback: any(named: 'callback'),
        ),
      ).called(1);
      verify(
        () => client.subscribe(
          destination: '/user/queue/errors',
          callback: any(named: 'callback'),
        ),
      ).called(1);
      verify(
        () => client.send(
          destination: '/app/sessions/session-1/open',
          body: '{}',
          headers: {'content-type': 'application/json'},
        ),
      ).called(1);
      expect(events.single, isA<LiveTransportConnected>());
    },
  );

  test('maps typed topic envelopes to domain violation events', () async {
    final eventFuture = transport.events.firstWhere(
      (event) => event is LiveViolationReceived,
    );
    await transport.connect(
      accessToken: 'jwt',
      sessionPublicId: 'session-1',
      canControl: false,
    );
    config.onConnect(StompFrame(command: 'CONNECTED'));
    final callback =
        verify(
              () => client.subscribe(
                destination: '/topic/proctor-sessions/session-1',
                callback: captureAny(named: 'callback'),
              ),
            ).captured.single
            as StompFrameCallback;

    callback(
      StompFrame(
        command: 'MESSAGE',
        body:
            '{"eventId":"violation-1","eventType":"VIOLATION_DETECTED",'
            '"sessionPublicId":"session-1","occurredAt":"2026-07-28T01:03:04Z",'
            '"data":{"publicId":"violation-1","attemptPublicId":"attempt-1",'
            '"violationType":"TAB_SWITCH","detail":"Focus changed",'
            '"sequenceNo":1,"hash":"abc","detectedAt":"2026-07-28T01:03:04Z"}}',
      ),
    );

    final event = await eventFuture as LiveViolationReceived;
    expect(event.violation.publicId, 'violation-1');
    expect(event.violation.type.wireName, 'TAB_SWITCH');
    verifyNever(
      () => client.send(
        destination: any(named: 'destination'),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    );
  });
}
