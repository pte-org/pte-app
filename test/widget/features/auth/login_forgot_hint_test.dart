import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/auth/constants/auth_strings.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/auth/presentation/pages/login_page.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  testWidgets(
    'the sign-in screen tells a student who forgot the password to contact their centre',
    (tester) async {
      final bloc = _MockAuthBloc();
      when(() => bloc.state).thenReturn(const AuthIdle());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const LoginPage(),
          ),
        ),
      );

      expect(find.text(AuthStrings.forgotPasswordHint), findsOneWidget);
    },
  );
}
