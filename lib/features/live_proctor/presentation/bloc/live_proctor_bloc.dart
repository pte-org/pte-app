import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/live_proctor_transport.dart';
import '../../domain/live_proctor_types.dart';
import '../../domain/repositories/live_proctor_repository.dart';
import 'live_proctor_event.dart';
import 'live_proctor_state.dart';

class LiveProctorBloc extends Bloc<LiveProctorEvent, LiveProctorState> {
  LiveProctorBloc({
    required LiveProctorRepository repository,
    required LiveProctorTransport transport,
    required String? Function() readAccessToken,
  }) : _repository = repository,
       _transport = transport,
       _readAccessToken = readAccessToken,
       super(const LiveProctorState()) {
    on<LiveProctorStarted>(_onStarted);
    on<LiveTransportEventReceived>(_onTransportEvent);
    on<ProctorCommandRequested>(_onCommand);
    on<ViolationFlagRequested>(_onViolation);
    on<LiveReconnectRequested>(_onManualReconnect);
    on<LiveProctorStopped>(_onStopped);
  }

  static const reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];

  final LiveProctorRepository _repository;
  final LiveProctorTransport _transport;
  final String? Function() _readAccessToken;

  StreamSubscription<LiveTransportEvent>? _transportSubscription;
  Timer? _reconnectTimer;
  String? _sessionPublicId;
  bool _canControl = false;
  bool _stopped = false;

  Future<void> _onStarted(
    LiveProctorStarted event,
    Emitter<LiveProctorState> emit,
  ) async {
    _stopped = false;
    _sessionPublicId = event.sessionPublicId;
    _canControl = event.canControl;
    await _transportSubscription?.cancel();
    _transportSubscription = _transport.events.listen(
      (event) => add(LiveTransportEventReceived(event)),
    );
    emit(
      LiveProctorState(
        status: LiveProctorStatus.connecting,
        canControl: event.canControl,
      ),
    );
    await _connect();
  }

  Future<void> _onTransportEvent(
    LiveTransportEventReceived event,
    Emitter<LiveProctorState> emit,
  ) async {
    switch (event.event) {
      case LiveTransportConnected():
        _reconnectTimer?.cancel();
        emit(
          state.copyWith(
            status: LiveProctorStatus.connected,
            reconnectAttempt: 0,
          ),
        );
        await _recoverSnapshot(emit);
      case LiveProctorSessionOpened(:final session):
        emit(state.copyWith(proctorSession: session));
      case LiveViolationReceived(:final violation):
        emit(state.copyWith(violations: _merge([violation])));
      case LiveCommandAccepted():
        emit(state.copyWith(commandPending: false, message: 'Command queued'));
      case LiveTransportDisconnected(:final error):
        if (!_stopped) {
          _scheduleReconnect(emit, error);
        }
      case LiveTransportFailure(:final error):
        emit(
          state.copyWith(
            status: LiveProctorStatus.failure,
            commandPending: false,
            message: error.toString(),
          ),
        );
    }
  }

  void _onCommand(
    ProctorCommandRequested event,
    Emitter<LiveProctorState> emit,
  ) {
    final proctorSessionId = state.proctorSession?.publicId;
    if (!_canControl || proctorSessionId == null || state.commandPending) {
      return;
    }
    emit(state.copyWith(commandPending: true, message: null));
    _transport.issueCommand(
      proctorSessionPublicId: proctorSessionId,
      attemptPublicId: event.attemptPublicId,
      commandType: event.commandType,
      extraSeconds: event.extraSeconds,
    );
  }

  void _onViolation(
    ViolationFlagRequested event,
    Emitter<LiveProctorState> emit,
  ) {
    final proctorSessionId = state.proctorSession?.publicId;
    if (!_canControl || proctorSessionId == null) return;
    _transport.flagViolation(
      proctorSessionPublicId: proctorSessionId,
      attemptPublicId: event.attemptPublicId,
      violationType: event.violationType,
      detail: event.detail,
    );
  }

  Future<void> _onManualReconnect(
    LiveReconnectRequested event,
    Emitter<LiveProctorState> emit,
  ) async {
    _reconnectTimer?.cancel();
    emit(state.copyWith(status: LiveProctorStatus.connecting, message: null));
    await _connect();
  }

  Future<void> _onStopped(
    LiveProctorStopped event,
    Emitter<LiveProctorState> emit,
  ) async {
    _stopped = true;
    _reconnectTimer?.cancel();
    await _transport.disconnect();
  }

  Future<void> _connect() async {
    final token = _readAccessToken();
    final sessionId = _sessionPublicId;
    if (token == null || sessionId == null) {
      add(
        const LiveTransportEventReceived(
          LiveTransportFailure('Authentication required'),
        ),
      );
      return;
    }
    await _transport.connect(
      accessToken: token,
      sessionPublicId: sessionId,
      canControl: _canControl,
    );
  }

  Future<void> _recoverSnapshot(Emitter<LiveProctorState> emit) async {
    final sessionId = _sessionPublicId;
    if (sessionId == null) return;
    try {
      final snapshot = await _repository.loadViolations(sessionId);
      emit(state.copyWith(violations: _merge(snapshot)));
    } catch (error) {
      emit(state.copyWith(message: 'Snapshot recovery failed: $error'));
    }
  }

  List<ViolationEvent> _merge(Iterable<ViolationEvent> incoming) {
    final byId = <String, ViolationEvent>{
      for (final item in state.violations) item.publicId: item,
    };
    for (final item in incoming) {
      final current = byId[item.publicId];
      if (current == null || item.sequenceNo >= current.sequenceNo) {
        byId[item.publicId] = item;
      }
    }
    final result = byId.values.toList()
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    return List.unmodifiable(result);
  }

  void _scheduleReconnect(Emitter<LiveProctorState> emit, Object? error) {
    final attempt = state.reconnectAttempt;
    if (attempt >= reconnectDelays.length) {
      emit(
        state.copyWith(
          status: LiveProctorStatus.reconnectFailed,
          message: error?.toString() ?? 'Connection lost',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: LiveProctorStatus.reconnecting,
        reconnectAttempt: attempt + 1,
        message: error?.toString(),
      ),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelays[attempt], _connect);
  }

  @override
  Future<void> close() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    await _transportSubscription?.cancel();
    await _transport.disconnect();
    return super.close();
  }
}
