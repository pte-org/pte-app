import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/live_proctor_types.dart';
import '../bloc/assigned_sessions_bloc.dart';
import '../bloc/assigned_sessions_event.dart';
import '../bloc/assigned_sessions_state.dart';
import 'live_proctor_page.dart';

class ProctorWorkspacePage extends StatelessWidget {
  const ProctorWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        GetIt.instance<AssignedSessionsBloc>()
          ..add(const AssignedSessionsRequested()),
    child: const _ProctorWorkspaceView(),
  );
}

class _ProctorWorkspaceView extends StatelessWidget {
  const _ProctorWorkspaceView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AppStrings.proctorWorkspaceTitle),
      actions: [
        TextButton(
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
          child: const Text(AppStrings.logout),
        ),
      ],
    ),
    body: BlocBuilder<AssignedSessionsBloc, AssignedSessionsState>(
      builder: (context, state) => switch (state) {
        AssignedSessionsInitial() ||
        AssignedSessionsLoading() => const LoadingView(),
        AssignedSessionsEmpty() => const Center(
          child: Text(AppStrings.assignedSessionsEmpty),
        ),
        AssignedSessionsFailure() => Center(
          child: ElevatedButton(
            onPressed: () => context.read<AssignedSessionsBloc>().add(
              const AssignedSessionsRequested(),
            ),
            child: const Text(AppStrings.retry),
          ),
        ),
        AssignedSessionsLoaded(:final sessions) => ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (_, index) => _AssignmentTile(session: sessions[index]),
        ),
      },
    ),
  );
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.session});

  final AssignedProctorSession session;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(session.name),
    subtitle: Text('${session.status} · ${session.opensAt.toLocal()}'),
    trailing: const Icon(Icons.live_tv),
    onTap: () => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LiveProctorEntryPage(
          sessionPublicId: session.sessionPublicId,
          canControl: true,
        ),
      ),
    ),
  );
}
