import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/session_types.dart';
import '../bloc/session_create_bloc.dart';
import '../bloc/session_detail_bloc.dart';
import '../bloc/session_detail_event.dart';
import '../bloc/session_list_bloc.dart';
import '../bloc/session_list_event.dart';
import '../bloc/session_list_state.dart';
import 'session_create_page.dart';
import 'session_detail_page.dart';

class SessionListPage extends StatelessWidget {
  const SessionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<SessionListBloc>()..add(const SessionListRequested()),
      child: const _SessionListView(),
    );
  }
}

class _SessionListView extends StatelessWidget {
  const _SessionListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessionsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        label: const Text(AppStrings.createSession),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<SessionListBloc, SessionListState>(
        builder: (context, state) => switch (state) {
          SessionListInitial() || SessionListLoading() => const LoadingView(),
          SessionListEmpty() => const Center(
            child: Text(AppStrings.sessionsEmpty),
          ),
          SessionListFailure() => Center(
            child: ElevatedButton(
              onPressed: () => _reload(context),
              child: const Text(AppStrings.retry),
            ),
          ),
          SessionListLoaded(:final sessions) => ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, index) => _SessionTile(
              session: sessions[index],
              onTap: () => _openDetail(context, sessions[index].publicId),
            ),
          ),
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await Navigator.of(context).push<ExamSession>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<SessionCreateBloc>(),
          child: const SessionCreatePage(),
        ),
      ),
    );
    if (!context.mounted || created == null) return;
    _reload(context);
  }

  Future<void> _openDetail(BuildContext context, String publicId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              GetIt.instance<SessionDetailBloc>()
                ..add(SessionDetailRequested(publicId)),
          child: const SessionDetailPage(),
        ),
      ),
    );
    if (context.mounted) _reload(context);
  }

  void _reload(BuildContext context) =>
      context.read<SessionListBloc>().add(const SessionListRequested());
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});
  final ExamSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(session.name),
    subtitle: Text('${session.status.wireName} · ${session.opensAt.toLocal()}'),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
