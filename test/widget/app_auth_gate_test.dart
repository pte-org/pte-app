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
import 'package:pte_app/features/auth/presentation/pages/login_page.dart';
import 'package:pte_app/features/host_console/presentation/pages/host_console_page.dart';
import 'package:pte_app/features/live_proctor/presentation/pages/proctor_workspace_page.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_types.dart';
import 'package:pte_app/features/live_proctor/domain/repositories/live_proctor_repository.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/assigned_sessions_bloc.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakeLiveProctorRepository implements LiveProctorRepository {
  @override
  Future<List<AssignedProctorSession>> loadAssignedSessions() async => const [];

  @override
  Future<List<ViolationEvent>> loadViolations(String sessionPublicId) async =>
      const [];
}

void main() {
  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
    GetIt.instance.registerFactory<AssignedSessionsBloc>(
      () => AssignedSessionsBloc(repository: _FakeLiveProctorRepository()),
    );
  });

  tearDownAll(() => GetIt.instance.unregister<AssignedSessionsBloc>());

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

  testWidgets('AuthAuthenticating renders LoadingView', (tester) async {
    final bloc = _MockAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      buildSubject(const AuthAuthenticating(), bloc: bloc),
    );

    expect(find.byType(LoadingView), findsOneWidget);
  });

  for (final role in <String>['HOST_ADMIN', 'HOST_AUTHOR']) {
    testWidgets('$role enters HostConsolePage', (tester) async {
      final bloc = _MockAuthBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        buildSubject(
          AuthAuthenticated(JwtClaims(roles: [role], tenantId: 'tenant-1')),
          bloc: bloc,
        ),
      );

      expect(find.byType(HostConsolePage), findsOneWidget);
    });
  }

  testWidgets('non-Host claims keep the existing student workspace', (
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

    expect(find.byType(HostConsolePage), findsNothing);
    expect(find.text(AppStrings.studentWorkspacePlaceholder), findsOneWidget);
  });

  testWidgets('PROCTOR enters the assigned-session workspace', (tester) async {
    final bloc = _MockAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      buildSubject(
        const AuthAuthenticated(
          JwtClaims(roles: ['PROCTOR'], tenantId: 'tenant-1'),
        ),
        bloc: bloc,
      ),
    );

    expect(find.byType(ProctorWorkspacePage), findsOneWidget);
    expect(find.byType(HostConsolePage), findsNothing);
  });

  testWidgets('Host console logout dispatches LogoutRequested', (tester) async {
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
    await tester.tap(find.widgetWithText(TextButton, AppStrings.logout));

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
      Navigator.of(tester.element(find.byType(HostConsolePage))).push(
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
