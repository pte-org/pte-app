import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../authoring/presentation/pages/blueprint_list_page.dart';
import '../../../authoring/presentation/pages/question_list_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../host_audit/presentation/bloc/notification_audit_bloc.dart';
import '../../../host_audit/presentation/bloc/notification_audit_event.dart';
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
                  builder: (_) => const QuestionListPage(),
                ),
              ),
              child: const Text(AppStrings.questionsTitle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BlueprintListPage(),
                ),
              ),
              child: const Text(AppStrings.blueprintsTitle),
            ),
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
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        GetIt.instance<NotificationAuditBloc>()
                          ..add(const NotificationAuditRequested()),
                    child: const NotificationAuditPage(),
                  ),
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
