import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class HostConsolePage extends StatelessWidget {
  const HostConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.hostConsoleTitle),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
      body: const Center(child: Text(AppStrings.hostConsoleWelcome)),
    );
  }
}
