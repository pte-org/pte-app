import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/scheduling/domain/session_types.dart';
import 'package:pte_app/features/scheduling/domain/usecases/assign_class.dart';
import 'package:pte_app/features/scheduling/domain/usecases/create_session.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_assigned_classes.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_session.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_sessions.dart';
import 'package:pte_app/features/scheduling/domain/usecases/unassign_class.dart';
import 'package:pte_app/features/scheduling/domain/usecases/update_session_status.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_create_bloc.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_create_event.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_create_state.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_detail_bloc.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_detail_event.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_detail_state.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_list_bloc.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_list_event.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_list_state.dart';

class _MockLoadSessions extends Mock implements LoadSessions {}

class _MockCreateSession extends Mock implements CreateSession {}

class _MockLoadSession extends Mock implements LoadSession {}

class _MockLoadAssignedClasses extends Mock implements LoadAssignedClasses {}

class _MockAssignClass extends Mock implements AssignClass {}

class _MockUnassignClass extends Mock implements UnassignClass {}

class _MockOpenSession extends Mock implements OpenSession {}

class _MockCloseSession extends Mock implements CloseSession {}

final session = ExamSession(
  publicId: 'session-1',
  name: 'Mock exam',
  tenantId: 'tenant-1',
  snapshotPublicId: 'snap-1',
  opensAt: DateTime.utc(2026, 7, 29, 8),
  closesAt: DateTime.utc(2026, 7, 29, 10),
  status: SessionStatus.scheduled,
);
const assignedClasses = [
  AssignedClass(sessionPublicId: 'session-1', classPublicId: 'class-1'),
];

void main() {
  setUpAll(() {
    registerFallbackValue(
      CreateSessionInput(
        name: 'Exam',
        skills: {ExamSkill.speaking},
        opensAt: DateTime.utc(2026, 7, 29),
        closesAt: DateTime.utc(2026, 7, 30),
      ),
    );
  });

  blocTest<SessionListBloc, SessionListState>(
    'loads sessions',
    setUp: () {
      loadSessions = _MockLoadSessions();
      when(loadSessions.call).thenAnswer((_) async => [session]);
    },
    build: () => SessionListBloc(loadSessions: loadSessions),
    act: (bloc) => bloc.add(const SessionListRequested()),
    expect: () => [isA<SessionListLoading>(), isA<SessionListLoaded>()],
  );

  blocTest<SessionCreateBloc, SessionCreateState>(
    'rejects an invalid window before calling create',
    setUp: () => createSession = _MockCreateSession(),
    build: () => SessionCreateBloc(
      createSession: createSession,
      clock: () => DateTime.utc(2026, 7, 28),
    ),
    act: (bloc) => bloc.add(
      SessionCreateSubmitted(
        CreateSessionInput(
          name: 'Exam',
          skills: {ExamSkill.speaking},
          opensAt: DateTime.utc(2026, 7, 27),
          closesAt: DateTime.utc(2026, 7, 29),
        ),
      ),
    ),
    expect: () => [isA<SessionCreateInvalid>()],
    verify: (_) => verifyNever(() => createSession(any())),
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'reloads authoritative detail when open conflicts',
    setUp: () {
      loadSession = _MockLoadSession();
      loadAssignedClasses = _MockLoadAssignedClasses();
      assignClass = _MockAssignClass();
      unassignClass = _MockUnassignClass();
      openSession = _MockOpenSession();
      closeSession = _MockCloseSession();
      when(() => loadSession('session-1')).thenAnswer((_) async => session);
      when(
        () => loadAssignedClasses('session-1'),
      ).thenAnswer((_) async => assignedClasses);
      when(
        () => openSession('session-1'),
      ).thenThrow(const ConflictException('STALE_SESSION_STATE'));
    },
    build: buildDetailBloc,
    act: (bloc) async {
      bloc.add(const SessionDetailRequested('session-1'));
      await bloc.stream.firstWhere((state) => state is SessionDetailReady);
      bloc.add(const SessionOpenRequested());
    },
    expect: () => [
      isA<SessionDetailLoading>(),
      isA<SessionDetailReady>(),
      isA<SessionDetailTransitioning>(),
      isA<SessionDetailConflict>(),
    ],
    verify: (_) => verify(() => loadSession('session-1')).called(2),
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'assigns a Class and reloads the assigned-Classes list',
    setUp: () {
      loadSession = _MockLoadSession();
      loadAssignedClasses = _MockLoadAssignedClasses();
      assignClass = _MockAssignClass();
      unassignClass = _MockUnassignClass();
      openSession = _MockOpenSession();
      closeSession = _MockCloseSession();
      when(() => loadSession('session-1')).thenAnswer((_) async => session);
      when(() => loadAssignedClasses('session-1')).thenAnswer(
        (_) async => const [],
      );
      when(
        () => assignClass('session-1', 'class-1'),
      ).thenAnswer((_) async => assignedClasses.single);
    },
    build: buildDetailBloc,
    act: (bloc) async {
      bloc.add(const SessionDetailRequested('session-1'));
      await bloc.stream.firstWhere((state) => state is SessionDetailReady);
      when(
        () => loadAssignedClasses('session-1'),
      ).thenAnswer((_) async => assignedClasses);
      bloc.add(const ClassAssignRequested('class-1'));
    },
    expect: () => [
      isA<SessionDetailLoading>(),
      isA<SessionDetailReady>(),
      isA<SessionDetailTransitioning>(),
      predicate<SessionDetailReady>(
        (state) => state.assignedClasses.single.classPublicId == 'class-1',
      ),
    ],
    verify: (_) => verify(() => assignClass('session-1', 'class-1')).called(1),
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'does not assign a Class once the session is no longer Scheduled',
    setUp: () {
      loadSession = _MockLoadSession();
      loadAssignedClasses = _MockLoadAssignedClasses();
      assignClass = _MockAssignClass();
      unassignClass = _MockUnassignClass();
      openSession = _MockOpenSession();
      closeSession = _MockCloseSession();
      when(() => loadSession('session-1')).thenAnswer(
        (_) async => ExamSession(
          publicId: 'session-1',
          name: 'Mock exam',
          tenantId: 'tenant-1',
          snapshotPublicId: 'snap-1',
          opensAt: DateTime.utc(2026, 7, 29, 8),
          closesAt: DateTime.utc(2026, 7, 29, 10),
          status: SessionStatus.open,
        ),
      );
      when(
        () => loadAssignedClasses('session-1'),
      ).thenAnswer((_) async => const []);
    },
    build: buildDetailBloc,
    act: (bloc) async {
      bloc.add(const SessionDetailRequested('session-1'));
      await bloc.stream.firstWhere((state) => state is SessionDetailReady);
      bloc.add(const ClassAssignRequested('class-1'));
    },
    expect: () => [isA<SessionDetailLoading>(), isA<SessionDetailReady>()],
    verify: (_) => verifyNever(() => assignClass(any(), any())),
  );
}

SessionDetailBloc buildDetailBloc() => SessionDetailBloc(
  loadSession: loadSession,
  loadAssignedClasses: loadAssignedClasses,
  assignClass: assignClass,
  unassignClass: unassignClass,
  openSession: openSession,
  closeSession: closeSession,
);

late LoadSessions loadSessions;
late CreateSession createSession;
late LoadSession loadSession;
late LoadAssignedClasses loadAssignedClasses;
late AssignClass assignClass;
late UnassignClass unassignClass;
late OpenSession openSession;
late CloseSession closeSession;
