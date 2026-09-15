import 'dart:async';

import 'package:pte_app/features/live_proctor/domain/live_proctor_transport.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_types.dart';

/// Dev-only [LiveProctorTransport] used when `AppConfig.useMockBackend` is
/// on: fakes the STOMP channel so live monitoring connects, opens a proctor
/// session (controller only, like the real server), streams a violation
/// every [violationInterval], and echoes flags/commands — no WebSocket.
class MockLiveProctorTransport implements LiveProctorTransport {
  MockLiveProctorTransport({
    this.violationInterval = const Duration(seconds: 12),
    this.latency = const Duration(milliseconds: 400),
  });

  final Duration violationInterval;
  final Duration latency;
  final StreamController<LiveTransportEvent> _events =
      StreamController<LiveTransportEvent>.broadcast();

  static const _liveViolations = [
    (ViolationType.tabSwitch, 'Exam window lost focus for 6 seconds'),
    (ViolationType.faceNotVisible, 'No face detected for 10 seconds'),
    (ViolationType.suspiciousAudio, 'Second voice detected near microphone'),
    (ViolationType.multipleFaces, 'Two faces detected in webcam frame'),
  ];

  static const _liveAttemptIds = [
    'mock-attempt-demo-1',
    'mock-attempt-demo-2',
    'mock-attempt-demo-3',
  ];

  Timer? _ticker;
  int _generation = 0;

  /// Starts above the seeded snapshot's sequence numbers (1-4) so live
  /// events merge after them in `LiveProctorBloc`.
  int _nextSequenceNo = 100;

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
    await Future<void>.delayed(latency);
    if (generation != _generation) return;

    _events.add(const LiveTransportConnected());
    if (canControl) {
      _events.add(
        LiveProctorSessionOpened(
          ProctorSession(
            publicId: 'mock-proctor-session-$sessionPublicId',
            sessionPublicId: sessionPublicId,
            status: 'OPEN',
            openedAt: DateTime.now().toUtc(),
          ),
        ),
      );
    }
    _ticker = Timer.periodic(violationInterval, (_) => _emitViolation());
  }

  @override
  void issueCommand({
    required String proctorSessionPublicId,
    required String attemptPublicId,
    required ProctorCommandType commandType,
  }) {
    final generation = _generation;
    unawaited(
      Future<void>.delayed(latency, () {
        if (generation == _generation) {
          _events.add(LiveCommandAccepted(attemptPublicId));
        }
      }),
    );
  }

  @override
  void flagViolation({
    required String proctorSessionPublicId,
    required String attemptPublicId,
    required ViolationType violationType,
    String? detail,
  }) {
    _emitViolation(
      type: violationType,
      attemptPublicId: attemptPublicId,
      detail: detail == null || detail.isEmpty ? 'Flagged by proctor' : detail,
    );
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    _ticker?.cancel();
    _ticker = null;
  }

  void _emitViolation({
    ViolationType? type,
    String? attemptPublicId,
    String? detail,
  }) {
    final sequenceNo = _nextSequenceNo++;
    final (sampleType, sampleDetail) =
        _liveViolations[sequenceNo % _liveViolations.length];
    _events.add(
      LiveViolationReceived(
        ViolationEvent(
          publicId: 'mock-live-violation-$sequenceNo',
          attemptPublicId:
              attemptPublicId ??
              _liveAttemptIds[sequenceNo % _liveAttemptIds.length],
          type: type ?? sampleType,
          detail: detail ?? sampleDetail,
          sequenceNo: sequenceNo,
          hash: 'sha256:mock-live-$sequenceNo',
          detectedAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }
}
