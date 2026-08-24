import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/scheduling/domain/session_types.dart';
import 'package:pte_app/features/scheduling/domain/usecases/create_session.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_session.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_sessions.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_snapshot_options.dart';
import 'package:pte_app/features/scheduling/domain/usecases/update_session_composition.dart';
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

class _MockLoadSnapshotOptions extends Mock implements LoadSnapshotOptions {}

class _MockUpdateComposition extends Mock implements UpdateSessionComposition {}

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
  composition: const [],
);
const options = [
  SnapshotTaskOption(
    taskType: 'READ_ALOUD',
    section: 'SPEAKING',
    title: 'Read aloud',
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(
      CreateSessionInput(
        name: 'Exam',
        snapshotPublicId: 'snap-1',
        opensAt: DateTime.utc(2026, 7, 29),
        closesAt: DateTime.utc(2026, 7, 30),
      ),
    );
    registerFallbackValue(SetCompositionInput(items: const []));
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
          snapshotPublicId: 'snap-1',
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
      loadOptions = _MockLoadSnapshotOptions();
      updateComposition = _MockUpdateComposition();
      openSession = _MockOpenSession();
      closeSession = _MockCloseSession();
      when(() => loadSession('session-1')).thenAnswer((_) async => session);
      when(() => loadOptions('snap-1')).thenAnswer((_) async => options);
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
}

SessionDetailBloc buildDetailBloc() => SessionDetailBloc(
  loadSession: loadSession,
  loadSnapshotOptions: loadOptions,
  updateComposition: updateComposition,
  openSession: openSession,
  closeSession: closeSession,
);

late LoadSessions loadSessions;
late CreateSession createSession;
late LoadSession loadSession;
late LoadSnapshotOptions loadOptions;
late UpdateSessionComposition updateComposition;
late OpenSession openSession;
late CloseSession closeSession;
