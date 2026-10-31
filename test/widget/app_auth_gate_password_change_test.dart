import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/app.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:pte_app/features/auth/presentation/pages/login_page.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  const claims = JwtClaims(
    roles: ['STUDENT'],
    tenantId: 't1',
    mustChangePassword: true,
  );

  Widget buildSubject(AuthState state, _MockAuthBloc bloc) {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const AppAuthGate(),
      ),
    );
  }

  // A temporary password blocks everything else, whatever the change attempt
  // is doing: the student must never reach the exam flow or the login form.
  for (final state in <AuthState>[
    const AuthPasswordChangeRequired(claims),
    const AuthPasswordChanging(claims),
    const AuthPasswordChangeFailed(claims, AuthException('wrong password')),
  ]) {
    testWidgets('${state.runtimeType} renders the change-password page', (
      tester,
    ) async {
      final bloc = _MockAuthBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildSubject(state, bloc));

      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });
  }
}
