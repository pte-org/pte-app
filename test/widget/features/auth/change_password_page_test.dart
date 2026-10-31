import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/auth/constants/auth_strings.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/auth/presentation/pages/change_password_page.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc bloc;

  const claims = JwtClaims(
    roles: ['STUDENT'],
    tenantId: 't1',
    mustChangePassword: true,
  );

  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
  });

  setUp(() {
    bloc = _MockAuthBloc();
    when(() => bloc.state).thenReturn(const AuthPasswordChangeRequired(claims));
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const ChangePasswordPage(),
      ),
    ),
  );

  Future<void> fill(
    WidgetTester tester, {
    String current = '',
    String next = '',
    String confirm = '',
  }) async {
    await tester.enterText(find.byKey(const Key('change-current')), current);
    await tester.enterText(find.byKey(const Key('change-new')), next);
    await tester.enterText(find.byKey(const Key('change-confirm')), confirm);
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pump();
  }

  testWidgets('empty fields show the required message and send nothing', (
    tester,
  ) async {
    await pump(tester);

    await fill(tester);

    expect(find.text(AuthStrings.changePasswordRequired), findsWidgets);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a short new password is refused', (tester) async {
    await pump(tester);

    await fill(tester, current: 'temp', next: 'short', confirm: 'short');

    expect(find.text(AuthStrings.changePasswordTooShort), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a mismatching confirmation is refused', (tester) async {
    await pump(tester);

    await fill(
      tester,
      current: 'temp',
      next: 'NewPassword456',
      confirm: 'NewPassword457',
    );

    expect(find.text(AuthStrings.changePasswordMismatch), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a valid form sends the change request', (tester) async {
    await pump(tester);

    await fill(
      tester,
      current: 'temp',
      next: 'NewPassword456',
      confirm: 'NewPassword456',
    );

    final sent =
        verify(() => bloc.add(captureAny())).captured.single
            as PasswordChangeSubmitted;
    expect(sent.currentPassword, 'temp');
    expect(sent.newPassword, 'NewPassword456');
  });

  testWidgets('the server failure is shown above the form', (tester) async {
    when(() => bloc.state).thenReturn(
      const AuthPasswordChangeFailed(
        claims,
        AuthException('wrong current password'),
      ),
    );
    await pump(tester);

    expect(find.byKey(const Key('change-error')), findsOneWidget);
  });

  testWidgets('the student can leave through sign out', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('change-signout')));

    verify(() => bloc.add(const LogoutRequested())).called(1);
  });
}
