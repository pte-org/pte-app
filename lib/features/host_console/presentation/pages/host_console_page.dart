import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../host_audit/presentation/pages/notification_audit_page.dart';
import '../../../scheduling/presentation/pages/session_list_page.dart';
import '../../domain/host_access_policy.dart';

class HostConsolePage extends StatelessWidget {
  const HostConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin =
        authState is AuthAuthenticated &&
        HostAccessPolicy.isHostAdmin(authState.claims);
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.hostConsoleWelcome),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionListPage(isAdmin: isAdmin),
                ),
              ),
              child: const Text(AppStrings.sessionsTitle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationAuditEntryPage(),
                ),
              ),
              child: const Text(AppStrings.notificationAuditTitle),
            ),
          ],
        ),
      ),
    );
  }
}
