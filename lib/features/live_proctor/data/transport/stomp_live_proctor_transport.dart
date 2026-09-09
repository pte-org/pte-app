import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/live_proctor_transport.dart';
import '../../domain/live_proctor_types.dart';

typedef StompClientFactory = StompClient Function(StompConfig config);

class StompLiveProctorTransport implements LiveProctorTransport {
  StompLiveProctorTransport({StompClientFactory? clientFactory})
    : _clientFactory =
          clientFactory ?? ((config) => StompClient(config: config));

  final StompClientFactory _clientFactory;
  final StreamController<LiveTransportEvent> _events =
      StreamController<LiveTransportEvent>.broadcast();

  StompClient? _client;
  String? _sessionPublicId;
  bool _canControl = false;
  bool _intentionalDisconnect = false;
  int _generation = 0;

  @override
  Stream<LiveTransportEvent> get events => _events.stream;

  @override
  Future<void> connect({
    required String accessToken,
    required String sessionPublicId,
    required bool canControl,
  }) async {
    await disconnect();
    final generation = ++_generation;
    _intentionalDisconnect = false;
    _sessionPublicId = sessionPublicId;
    _canControl = canControl;
    final gatewayWebSocketUrl = AppConfig.gatewayBaseUrl.replaceFirst(
      RegExp('^http'),
      'ws',
    );
    _client = _clientFactory(
      StompConfig(
        url: '$gatewayWebSocketUrl/api/proctor/ws',
        reconnectDelay: Duration.zero,
        connectionTimeout: const Duration(seconds: 10),
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        onConnect: (frame) => _onConnect(frame, generation),
        onStompError: (frame) {
          if (generation == _generation) {
            _emitFailure(
              frame.body ?? frame.headers['message'] ?? 'STOMP error',
            );
          }
        },
        onWebSocketError: (error) {
          if (generation == _generation) {
            _emitFailure(error ?? 'WebSocket error');
          }
        },
        onWebSocketDone: () {
          if (!_intentionalDisconnect && generation == _generation) {
            _events.add(const LiveTransportDisconnected());
          }
        },
      ),
    )..activate();
  }

  void _onConnect(StompFrame frame, int generation) {
    if (generation != _generation) return;
    final client = _client;
    final sessionId = _sessionPublicId;
    if (client == null || sessionId == null) return;
    client.subscribe(
      destination: '/topic/proctor-sessions/$sessionId',
      callback: _onTopicMessage,
    );
    client.subscribe(
      destination: '/user/queue/proctor-session',
      callback: _onSessionOpened,
    );
    client.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) => _emitFailure(frame.body ?? 'Proctor error'),
    );
    if (_canControl) {
      client.send(
        destination: '/app/sessions/$sessionId/open',
        body: '{}',
        headers: const {'content-type': 'application/json'},
      );
    }
    _events.add(const LiveTransportConnected());
  }

  void _onSessionOpened(StompFrame frame) {
    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      _events.add(
        LiveProctorSessionOpened(
          ProctorSession(
            publicId: json['publicId'] as String,
            sessionPublicId: json['sessionPublicId'] as String,
            status: json['status'] as String,
            openedAt: DateTime.parse(json['openedAt'] as String).toUtc(),
          ),
        ),
      );
    } catch (error) {
      _emitFailure(error);
    }
  }

  void _onTopicMessage(StompFrame frame) {
    try {
      final envelope = jsonDecode(frame.body!) as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>;
      switch (envelope['eventType'] as String) {
        case 'VIOLATION_DETECTED':
          _events.add(
            LiveViolationReceived(
              ViolationEvent(
                publicId: data['publicId'] as String,
                attemptPublicId: data['attemptPublicId'] as String,
                type: ViolationType.fromWire(data['violationType'] as String),
                detail: data['detail'] as String?,
                sequenceNo: data['sequenceNo'] as int,
                hash: data['hash'] as String,
                detectedAt: DateTime.parse(
                  data['detectedAt'] as String,
                ).toUtc(),
              ),
            ),
          );
        case 'COMMAND_ACCEPTED':
          _events.add(LiveCommandAccepted(data['attemptPublicId'] as String));
      }
    } catch (error) {
      _emitFailure(error);
    }
  }

  @override
  void issueCommand({
    required String proctorSessionPublicId,
    required String attemptPublicId,
    required ProctorCommandType commandType,
  }) {
    final payload = <String, dynamic>{
      'attemptPublicId': attemptPublicId,
      'commandType': commandType.wireName,
    };
    _client?.send(
      destination: '/app/proctor-sessions/$proctorSessionPublicId/commands',
      body: jsonEncode(payload),
      headers: const {'content-type': 'application/json'},
    );
  }

  @override
  void flagViolation({
    required String proctorSessionPublicId,
    required String attemptPublicId,
    required ViolationType violationType,
    String? detail,
  }) {
    final payload = <String, dynamic>{
      'attemptPublicId': attemptPublicId,
      'violationType': violationType.wireName,
    };
    if (detail != null && detail.isNotEmpty) {
      payload['detail'] = detail;
    }
    _client?.send(
      destination: '/app/proctor-sessions/$proctorSessionPublicId/violations',
      body: jsonEncode(payload),
      headers: const {'content-type': 'application/json'},
    );
  }

  void _emitFailure(Object error) {
    if (!_intentionalDisconnect) {
      _events.add(LiveTransportFailure(error));
    }
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    _intentionalDisconnect = true;
    _client?.deactivate();
    _client = null;
  }
}
