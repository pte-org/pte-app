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

  const temporary = JwtClaims(
    roles: ['STUDENT'],
    tenantId: 't1',
    mustChangePassword: true,
  );

  setUp(() {
    repository = _MockAuthRepository();
    scheduler = _MockProactiveRefreshScheduler();
    when(() => scheduler.scheduleFromTokenStore()).thenReturn(null);
  });

  AuthBloc buildBloc() =>
      AuthBloc(repository: repository, scheduler: scheduler);

  blocTest<AuthBloc, AuthState>(
    'a login with a temporary password stops at PasswordChangeRequired instead of Authenticated',
    setUp: () {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => temporary);
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const LoginRequested(email: 'a', password: 'temporary')),
    expect: () => [
      isA<AuthAuthenticating>(),
      isA<AuthPasswordChangeRequired>().having((s) => s.claims.roles, 'roles', [
        'STUDENT',
      ]),
    ],
    verify: (_) {
      verify(() => scheduler.scheduleFromTokenStore()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'a successful change moves on to Authenticated with the flag cleared',
    setUp: () {
      when(
        () => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});
    },
    build: buildBloc,
    seed: () => const AuthPasswordChangeRequired(temporary),
    act: (bloc) => bloc.add(
      const PasswordChangeSubmitted(
        currentPassword: 'temporary',
        newPassword: 'NewPassword456',
      ),
    ),
    expect: () => [
      isA<AuthPasswordChanging>(),
      isA<AuthAuthenticated>()
          .having(
            (s) => s.claims.mustChangePassword,
            'mustChangePassword',
            false,
          )
          .having((s) => s.claims.roles, 'roles', ['STUDENT']),
    ],
    verify: (_) {
      verify(
        () => repository.changePassword(
          currentPassword: 'temporary',
          newPassword: 'NewPassword456',
        ),
      ).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'a failed change keeps the student on the change screen with the reason',
    setUp: () {
      when(
        () => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(const AuthException('wrong current password'));
    },
    build: buildBloc,
    seed: () => const AuthPasswordChangeRequired(temporary),
    act: (bloc) => bloc.add(
      const PasswordChangeSubmitted(
        currentPassword: 'wrong',
        newPassword: 'NewPassword456',
      ),
    ),
    expect: () => [
      isA<AuthPasswordChanging>(),
      isA<AuthPasswordChangeFailed>()
          .having((s) => s.error, 'error', isA<AuthException>())
          .having(
            (s) => s.claims.mustChangePassword,
            'mustChangePassword',
            true,
          ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'a student can sign out from the change screen',
    setUp: () {
      when(() => scheduler.cancel()).thenReturn(null);
      when(() => repository.logout()).thenAnswer((_) async {});
    },
    build: buildBloc,
    seed: () => const AuthPasswordChangeRequired(temporary),
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [isA<AuthUnauthenticated>()],
  );
}
