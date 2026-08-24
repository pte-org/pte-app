import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/proactive_refresh_scheduler.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/auth/presentation/pages/login_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProactiveRefreshScheduler extends Mock
    implements ProactiveRefreshScheduler {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthRepository repository;
  late _MockProactiveRefreshScheduler scheduler;
  late AuthBloc authBloc;

  setUp(() {
    repository = _MockAuthRepository();
    scheduler = _MockProactiveRefreshScheduler();
    authBloc = AuthBloc(repository: repository, scheduler: scheduler);
  });

  tearDown(() async {
    await authBloc.close();
  });

  Widget buildSubject({AuthBloc? bloc}) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc ?? authBloc,
        child: const LoginPage(),
      ),
    );
  }

  testWidgets(
    'empty credentials show field errors without calling the repository',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(
        find.widgetWithText(ElevatedButton, AppStrings.loginSubmit),
      );
      await tester.pump();

      expect(find.text(AppStrings.loginEmailRequired), findsOneWidget);
      expect(find.text(AppStrings.loginPasswordRequired), findsOneWidget);
      verifyNever(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  testWidgets('valid credentials are trimmed and submitted through AuthBloc', (
    tester,
  ) async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const JwtClaims(roles: ['HOST_ADMIN'], tenantId: 'tenant-1'),
    );
    when(() => scheduler.scheduleFromTokenStore()).thenReturn(null);
    await tester.pumpWidget(buildSubject());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  host@example.com  ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.loginSubmit),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.login(email: 'host@example.com', password: 'secret123'),
    ).called(1);
  });

  testWidgets(
    'authentication failure keeps the form visible and shows feedback',
    (tester) async {
      final bloc = _MockAuthBloc();
      whenListen(
        bloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthError(AuthException('bad credentials')),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(buildSubject(bloc: bloc));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text(AppStrings.loginFailure), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
  );

  testWidgets('authenticating state disables submit and shows progress', (
    tester,
  ) async {
    final bloc = _MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticating(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(buildSubject(bloc: bloc));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
