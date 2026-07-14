import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/auth/domain/entities/auth_session.dart';
import 'package:aptis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aptis_app/features/auth/presentation/pages/auth_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _testCredential = 'student001';
const String _testPassword = 'Password123!';
const String _testAccessToken = 'access-token';
const String _testRefreshToken = 'refresh-token';
const int _testExpiresIn = 3600;

void main() {
  testWidgets('AuthLoginPage validates missing account before submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthLoginPage(
          authRepository: _FakeAuthRepository(),
          onLoginSuccess: (_) {},
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.loginButton));
    await tester.pump();

    expect(find.text(AppStrings.loginMissingAccount), findsOneWidget);
  });

  testWidgets('AuthLoginPage logs in candidate and emits session', (
    WidgetTester tester,
  ) async {
    AuthSession? capturedSession;
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AuthLoginPage(
          authRepository: repository,
          onLoginSuccess: (session) => capturedSession = session,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.loginAccountHint),
      _testCredential,
    );
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.loginPasswordHint),
      _testPassword,
    );
    await tester.tap(find.text(AppStrings.loginButton));
    await tester.pump();

    expect(repository.credential, _testCredential);
    expect(repository.password, _testPassword);
    expect(capturedSession?.isStudent, isTrue);
  });
}

class _FakeAuthRepository implements AuthRepository {
  String? credential;
  String? password;

  @override
  Future<AuthSession> login({
    required String credential,
    required String password,
  }) async {
    this.credential = credential;
    this.password = password;
    return const AuthSession(
      accessToken: _testAccessToken,
      refreshToken: _testRefreshToken,
      tokenType: 'Bearer',
      expiresIn: _testExpiresIn,
      role: 'STUDENT',
      userType: 'STUDENT',
      tenantId: null,
      mustChangePassword: false,
    );
  }
}
