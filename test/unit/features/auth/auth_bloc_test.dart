import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/proactive_refresh_scheduler.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProactiveRefreshScheduler extends Mock
    implements ProactiveRefreshScheduler {}

void main() {
  late _MockAuthRepository repository;
  late _MockProactiveRefreshScheduler scheduler;

  setUpAll(() {
    registerFallbackValue(const AuthIdle());
  });

  setUp(() {
    repository = _MockAuthRepository();
    scheduler = _MockProactiveRefreshScheduler();
    loginCompleter = Completer<JwtClaims>();
  });

  AuthBloc buildBloc() =>
      AuthBloc(repository: repository, scheduler: scheduler);

  blocTest<AuthBloc, AuthState>(
    'LoginRequested success emits Authenticating then Authenticated, and starts the proactive scheduler',
    setUp: () {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const JwtClaims(roles: ['STUDENT'], tenantId: 't1'),
      );
      when(() => scheduler.scheduleFromTokenStore()).thenReturn(null);
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const LoginRequested(email: 'a@b.com', password: 'secret')),
    expect: () => [
      isA<AuthAuthenticating>(),
      isA<AuthAuthenticated>().having((s) => s.claims.roles, 'roles', [
        'STUDENT',
      ]),
    ],
    verify: (_) {
      verify(() => scheduler.scheduleFromTokenStore()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'LoginRequested failure emits Authenticating then Error, never a boolean-flag shape',
    setUp: () {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('bad credentials'));
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const LoginRequested(email: 'a@b.com', password: 'wrong')),
    expect: () => [
      isA<AuthAuthenticating>(),
      isA<AuthError>().having((s) => s.error, 'error', isA<AuthException>()),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'LogoutRequested cancels the scheduler, calls repository.logout(), and reaches Unauthenticated',
    setUp: () {
      when(() => scheduler.cancel()).thenReturn(null);
      when(() => repository.logout()).thenAnswer((_) async {});
    },
    build: buildBloc,
    seed: () =>
        const AuthAuthenticated(JwtClaims(roles: ['STUDENT'], tenantId: 't1')),
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [isA<AuthUnauthenticated>()],
    verify: (_) {
      verify(() => scheduler.cancel()).called(1);
      verify(() => repository.logout()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'LogoutRequested is reachable from AuthError too, not just a happy-path authenticated state',
    setUp: () {
      when(() => scheduler.cancel()).thenReturn(null);
      when(() => repository.logout()).thenAnswer((_) async {});
    },
    build: buildBloc,
    seed: () => const AuthError(AuthException('stale session')),
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [isA<AuthUnauthenticated>()],
  );

  blocTest<AuthBloc, AuthState>(
    'a second LoginRequested while authentication is in flight is ignored',
    setUp: () {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => loginCompleter.future);
      when(() => scheduler.scheduleFromTokenStore()).thenReturn(null);
    },
    build: buildBloc,
    act: (bloc) async {
      bloc
        ..add(const LoginRequested(email: 'a@b.com', password: 'secret'))
        ..add(const LoginRequested(email: 'a@b.com', password: 'secret'));
      await Future<void>.delayed(Duration.zero);
      loginCompleter.complete(
        const JwtClaims(roles: ['HOST_ADMIN'], tenantId: 't1'),
      );
    },
    expect: () => [isA<AuthAuthenticating>(), isA<AuthAuthenticated>()],
    verify: (_) {
      verify(
        () => repository.login(email: 'a@b.com', password: 'secret'),
      ).called(1);
    },
  );
}

late Completer<JwtClaims> loginCompleter;
