import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/live_proctor/domain/live_proctor_transport.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_types.dart';
import 'package:pte_app/features/live_proctor/domain/repositories/live_proctor_repository.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/assigned_sessions_bloc.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/assigned_sessions_event.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/assigned_sessions_state.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_bloc.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_event.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_state.dart';

class _MockRepository extends Mock implements LiveProctorRepository {}

class _MockTransport extends Mock implements LiveProctorTransport {}

void main() {
  late _MockRepository repository;
  late _MockTransport transport;
  late StreamController<LiveTransportEvent> transportEvents;

  setUp(() {
    repository = _MockRepository();
    transport = _MockTransport();
    transportEvents = StreamController<LiveTransportEvent>.broadcast();
    when(() => transport.events).thenAnswer((_) => transportEvents.stream);
    when(
      () => transport.connect(
        accessToken: any(named: 'accessToken'),
        sessionPublicId: any(named: 'sessionPublicId'),
        canControl: any(named: 'canControl'),
      ),
    ).thenAnswer((_) async {});
    when(transport.disconnect).thenAnswer((_) async {});
  });

  tearDown(() => transportEvents.close());

  blocTest<AssignedSessionsBloc, AssignedSessionsState>(
    'loads the current proctor assignments',
    setUp: () {
      when(repository.loadAssignedSessions).thenAnswer(
        (_) async => [
          AssignedProctorSession(
            assignmentPublicId: 'assignment-1',
            sessionPublicId: 'session-1',
            name: 'Mock exam',
            opensAt: DateTime.utc(2026, 7, 28),
            closesAt: DateTime.utc(2026, 7, 28, 2),
            status: 'OPEN',
          ),
        ],
      );
    },
    build: () => AssignedSessionsBloc(repository: repository),
    act: (bloc) => bloc.add(const AssignedSessionsRequested()),
    expect: () => [
      isA<AssignedSessionsLoading>(),
      isA<AssignedSessionsLoaded>().having(
        (state) => state.sessions.single.sessionPublicId,
        'session id',
        'session-1',
      ),
    ],
  );

  blocTest<LiveProctorBloc, LiveProctorState>(
    'subscribes before snapshot recovery and merges events by public id',
    setUp: () {
      when(
        () => repository.loadViolations('session-1'),
      ).thenAnswer((_) async => [violation('violation-1', sequenceNo: 1)]);
    },
    build: () => LiveProctorBloc(
      repository: repository,
      transport: transport,
      readAccessToken: () => 'jwt',
    ),
    act: (bloc) async {
      bloc.add(
        const LiveProctorStarted(
          sessionPublicId: 'session-1',
          canControl: true,
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state.status == LiveProctorStatus.connecting,
      );
      transportEvents.add(const LiveTransportConnected());
      transportEvents.add(
        LiveViolationReceived(violation('violation-1', sequenceNo: 2)),
      );
    },
    wait: const Duration(milliseconds: 20),
    expect: () => [
      isA<LiveProctorState>().having(
        (state) => state.status,
        'status',
        LiveProctorStatus.connecting,
      ),
      isA<LiveProctorState>().having(
        (state) => state.status,
        'status',
        LiveProctorStatus.connected,
      ),
      isA<LiveProctorState>().having(
        (state) => state.violations.single.sequenceNo,
        'snapshot sequence',
        1,
      ),
      isA<LiveProctorState>().having(
        (state) => state.violations.single.sequenceNo,
        'newest duplicate',
        2,
      ),
    ],
    verify: (_) {
      verify(
        () => transport.connect(
          accessToken: 'jwt',
          sessionPublicId: 'session-1',
          canControl: true,
        ),
      ).called(1);
      verify(() => repository.loadViolations('session-1')).called(1);
    },
  );
}

ViolationEvent violation(String id, {required int sequenceNo}) =>
    ViolationEvent(
      publicId: id,
      attemptPublicId: 'attempt-1',
      type: ViolationType.tabSwitch,
      detail: 'Focus changed',
      sequenceNo: sequenceNo,
      hash: 'hash-$sequenceNo',
      detectedAt: DateTime.utc(2026, 7, 28, 1, sequenceNo),
    );
