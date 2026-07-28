import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_strings.dart';
import 'core/widgets/loading_view.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/host_console/domain/host_access_policy.dart';
import 'features/host_console/presentation/pages/host_console_page.dart';

class PteApp extends StatelessWidget {
  const PteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      home: BlocProvider<AuthBloc>.value(
        value: GetIt.instance<AuthBloc>(),
        child: const AppAuthGate(),
      ),
    );
  }
}

class AppAuthGate extends StatelessWidget {
  const AppAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthIdle ||
          state is AuthUnauthenticated ||
          state is AuthError,
      listener: (context, _) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return switch (state) {
            AuthIdle() ||
            AuthUnauthenticated() ||
            AuthError() => const LoginPage(),
            AuthAuthenticating() => const Scaffold(body: LoadingView()),
            AuthAuthenticated(:final claims)
                when HostAccessPolicy.canEnterHostConsole(claims) =>
              const HostConsolePage(),
            AuthAuthenticated() => const _StudentWorkspacePlaceholder(),
          };
        },
      ),
    );
  }
}

class _StudentWorkspacePlaceholder extends StatelessWidget {
  const _StudentWorkspacePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text(AppStrings.studentWorkspacePlaceholder)),
    );
  }
}
