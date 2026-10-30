import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/app.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/widgets/loading_view.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/auth/presentation/pages/exam_access_denied_page.dart';
import 'package:pte_app/features/auth/presentation/pages/login_page.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/pages/host_exam_preview_screen.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockHostExamPreviewRepository extends Mock
    implements HostExamPreviewRepository {}

class _MockPreviewAudioSession extends Mock implements PreviewAudioSession {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
    registerFallbackValue(
      const SessionResolutionRequested(rawInput: 'session-id'),
    );
    // StudentExamGate resolves an ExamAttemptBloc from GetIt eagerly (its
    // State's field initializer) — this gate-routing test only cares which
    // page class the router lands on, not the exam flow's own behavior, so
    // a bare stubbed mock (idle state, no events expected) is enough.
    GetIt.instance.registerFactory<ExamAttemptBloc>(() {
      final bloc = _MockExamAttemptBloc();
      whenListen(
        bloc,
        const Stream<ExamAttemptState>.empty(),
        initialState: const AttemptIdle(),
      );
      return bloc;
    });
    final repository = _MockHostExamPreviewRepository();
    when(() => repository.listExams()).thenAnswer((_) async => const []);
    GetIt.instance.registerSingleton<HostExamPreviewRepository>(repository);
    GetIt.instance.registerFactory<PreviewAudioSession>(() {
      final media = _MockPreviewAudioSession();
      when(() => media.dispose()).thenAnswer((_) async {});
      return media;
    });
  });

  tearDownAll(() {
    GetIt.instance.unregister<ExamAttemptBloc>();
    GetIt.instance.unregister<HostExamPreviewRepository>();
    GetIt.instance.unregister<PreviewAudioSession>();
  });

  Widget buildSubject(AuthState state, {required _MockAuthBloc bloc}) {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const AppAuthGate(),
      ),
    );
  }

  for (final state in <AuthState>[
    const AuthIdle(),
    const AuthUnauthenticated(),
    const AuthError(AuthException('expired')),
  ]) {
    testWidgets('${state.runtimeType} renders LoginPage', (tester) async {
      final bloc = _MockAuthBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildSubject(state, bloc: bloc));

      expect(find.byType(LoginPage), findsOneWidget);
    });
  }

  testWidgets('AuthAuthenticating keeps the login form and shows progress', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      buildSubject(const AuthAuthenticating(), bloc: bloc),
    );

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('student session follow-up preserves login credentials', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    final states = StreamController<AuthState>();
    whenListen(bloc, states.stream, initialState: const AuthIdle());
    addTearDown(states.close);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const AppAuthGate(),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@test.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');

    states.add(const AuthAuthenticating());
    await tester.pump();
    states.add(
      const AuthAuthenticated(
        JwtClaims(roles: ['STUDENT'], tenantId: 'tenant-1'),
      ),
    );
    await tester.pump();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.elementAt(0).controller?.text, 'student@test.local');
    expect(fields.elementAt(1).controller?.text, 'secret123');
    expect(find.text(AppStrings.loginSessionIdRequiredHint), findsOneWidget);
  });

  for (final roles in <List<String>>[
    ['HOST_AUTHOR'],
    ['PROCTOR'],
    ['EXAMINER'],
    ['PLATFORM_ADMIN'],
    [],
  ]) {
    testWidgets('roles $roles are refused the exam client', (tester) async {
      final bloc = _MockAuthBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        buildSubject(
          AuthAuthenticated(JwtClaims(roles: roles, tenantId: 'tenant-1')),
          bloc: bloc,
        ),
      );

      expect(find.byType(ExamAccessDeniedPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(StudentExamGate), findsNothing);
    });
  }

  testWidgets('HOST_ADMIN requires the same exam-code login as students', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      buildSubject(
        const AuthAuthenticated(
          JwtClaims(roles: ['HOST_ADMIN'], tenantId: 'tenant-1'),
        ),
        bloc: bloc,
      ),
    );

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HostExamPreviewScreen), findsNothing);
    expect(find.byType(StudentExamGate), findsNothing);
    expect(find.byType(ExamAccessDeniedPage), findsNothing);
  });

  for (final roles in [
    <String>['HOST_ADMIN'],
    <String>['HOST_ADMIN', 'STUDENT'],
  ]) {
    testWidgets(
      '$roles enters the exam code directly without a student attempt',
      (tester) async {
        final bloc = _MockAuthBloc();
        final states = StreamController<AuthState>();
        whenListen(bloc, states.stream, initialState: const AuthIdle());
        addTearDown(states.close);
        addTearDown(bloc.close);
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: bloc,
              child: const AppAuthGate(),
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'host@test.local',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password');
        await tester.enterText(find.byType(TextFormField).at(2), 'E2E-LOCAL');
        await tester.tap(find.text(AppStrings.loginSubmit));
        states.add(
          AuthAuthenticated(JwtClaims(roles: roles, tenantId: 'tenant-1')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HostExamPreviewScreen), findsOneWidget);
        expect(
          tester
              .widget<HostExamPreviewScreen>(find.byType(HostExamPreviewScreen))
              .sessionInput,
          'E2E-LOCAL',
        );
        expect(find.byType(StudentExamGate), findsNothing);
        expect(find.text('Host exam preview'), findsNothing);
      },
    );
  }

  testWidgets('student without a session ID returns to login for one', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      buildSubject(
        const AuthAuthenticated(
          JwtClaims(roles: ['STUDENT'], tenantId: 'tenant-1'),
        ),
        bloc: bloc,
      ),
    );

    expect(find.byType(ExamAccessDeniedPage), findsNothing);
    expect(find.byType(StudentExamGate), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text(AppStrings.loginSessionIdRequiredHint), findsOneWidget);
  });

  testWidgets('student gate starts the session ID supplied at login once', (
    tester,
  ) async {
    final bloc = _MockExamAttemptBloc();
    whenListen(
      bloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: const AttemptIdle(),
    );
    GetIt.instance.unregister<ExamAttemptBloc>();
    GetIt.instance.registerFactory<ExamAttemptBloc>(() => bloc);
    addTearDown(() {
      GetIt.instance.unregister<ExamAttemptBloc>();
      GetIt.instance.registerFactory<ExamAttemptBloc>(() {
        final fallbackBloc = _MockExamAttemptBloc();
        whenListen(
          fallbackBloc,
          const Stream<ExamAttemptState>.empty(),
          initialState: const AttemptIdle(),
        );
        return fallbackBloc;
      });
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentExamGate(initialSessionId: '  session-123  '),
      ),
    );
    await tester.pump();

    verify(
      () => bloc.add(
        any(
          that: isA<SessionResolutionRequested>().having(
            (event) => event.rawInput,
            'rawInput',
            'session-123',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('student gate shows recovery actions when session start fails', (
    tester,
  ) async {
    final bloc = _MockExamAttemptBloc();
    whenListen(
      bloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: const AttemptError(
        SessionResolutionException('Exam code cannot be empty.'),
      ),
    );
    GetIt.instance.unregister<ExamAttemptBloc>();
    GetIt.instance.registerFactory<ExamAttemptBloc>(() => bloc);
    addTearDown(() {
      GetIt.instance.unregister<ExamAttemptBloc>();
      GetIt.instance.registerFactory<ExamAttemptBloc>(() {
        final fallbackBloc = _MockExamAttemptBloc();
        whenListen(
          fallbackBloc,
          const Stream<ExamAttemptState>.empty(),
          initialState: const AttemptIdle(),
        );
        return fallbackBloc;
      });
    });

    await tester.pumpWidget(
      const MaterialApp(home: StudentExamGate(initialSessionId: 'session-123')),
    );

    expect(
      find.text(ExamAttemptStrings.sessionResolutionFailureMessage),
      findsOneWidget,
    );
    expect(find.text(ExamAttemptStrings.attemptStartRetry), findsOneWidget);
    expect(
      find.text(ExamAttemptStrings.attemptStartChangeSession),
      findsOneWidget,
    );
    expect(find.byType(LoadingView), findsNothing);
    expect(find.text('Enter session ID'), findsNothing);
  });

  testWidgets('refused account logout dispatches LogoutRequested', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      buildSubject(
        const AuthAuthenticated(
          JwtClaims(roles: ['HOST_AUTHOR'], tenantId: 'tenant-1'),
        ),
        bloc: bloc,
      ),
    );
    await tester.tap(find.text(AppStrings.logout));

    verify(() => bloc.add(any(that: isA<LogoutRequested>()))).called(1);
  });

  testWidgets('losing authentication removes every protected pushed route', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    final states = StreamController<AuthState>();
    whenListen(
      bloc,
      states.stream,
      initialState: const AuthAuthenticated(
        JwtClaims(roles: ['HOST_ADMIN'], tenantId: 'tenant-1'),
      ),
    );
    addTearDown(states.close);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const AppAuthGate(),
        ),
      ),
    );

    unawaited(
      Navigator.of(tester.element(find.byType(LoginPage))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('protected route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('protected route'), findsOneWidget);

    states.add(const AuthUnauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('protected route'), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
