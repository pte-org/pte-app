import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../host_users/domain/usecases/load_host_users.dart';
import '../../../host_audit/presentation/pages/violation_audit_page.dart';
import '../../../live_proctor/presentation/pages/live_proctor_page.dart';
import '../../../scoring_review/presentation/pages/session_scoring_page.dart';
import '../bloc/session_detail_bloc.dart';
import '../bloc/participant_command_bloc.dart';
import '../bloc/session_detail_event.dart';
import '../bloc/session_detail_state.dart';
import 'participant_management_page.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessionDetailTitle)),
      body: BlocBuilder<SessionDetailBloc, SessionDetailState>(
        builder: (context, state) => switch (state) {
          SessionDetailInitial() ||
          SessionDetailLoading() => const LoadingView(),
          SessionDetailData() => _SessionDetailBody(
            data: state,
            isAdmin: isAdmin,
          ),
          SessionDetailFailure(:final data) when data != null =>
            _SessionDetailBody(
              data: data,
              isAdmin: isAdmin,
              mutationFailed: true,
            ),
          SessionDetailFailure() => const Center(
            child: Text(AppStrings.sessionsLoadFailure),
          ),
        },
      ),
    );
  }
}

class _SessionDetailBody extends StatefulWidget {
  const _SessionDetailBody({
    required this.data,
    required this.isAdmin,
    this.mutationFailed = false,
  });
  final SessionDetailData data;
  final bool isAdmin;
  final bool mutationFailed;

  @override
  State<_SessionDetailBody> createState() => _SessionDetailBodyState();
}

class _SessionDetailBodyState extends State<_SessionDetailBody> {
  final _classPublicIdController = TextEditingController();

  @override
  void dispose() {
    _classPublicIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.data.session;
    final busy = widget.data is SessionDetailTransitioning;
    final canModifyClasses = session.status.isScheduled;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      children: [
        Text(session.name, style: Theme.of(context).textTheme.headlineSmall),
        Text('${AppStrings.sessionStatusLabel}: ${session.status.wireName}'),
        Text('${AppStrings.sessionSnapshotLabel}: ${session.snapshotPublicId}'),
        Text(
          '${AppStrings.sessionWindowLabel}: '
          '${session.opensAt.toIso8601String()} — '
          '${session.closesAt.toIso8601String()}',
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Text(
          AppStrings.assignedClassesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (!canModifyClasses) const Text(AppStrings.classAssignmentLocked),
        if (widget.data.assignedClasses.isEmpty)
          const Text(AppStrings.assignedClassesEmpty)
        else
          for (final assignedClass in widget.data.assignedClasses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(assignedClass.classPublicId),
              trailing: canModifyClasses
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: busy
                          ? null
                          : () => _unassignClass(assignedClass.classPublicId),
                    )
                  : null,
            ),
        if (canModifyClasses)
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('class-public-id'),
                  controller: _classPublicIdController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.classPublicIdLabel,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              ElevatedButton(
                onPressed: busy ? null : _assignClass,
                child: const Text(AppStrings.assignClass),
              ),
            ],
          ),
        if (widget.data is SessionDetailConflict)
          const Text(AppStrings.sessionConflict),
        if (widget.mutationFailed)
          const Text(AppStrings.sessionMutationFailure),
        const SizedBox(height: AppDimensions.spacingMedium),
        if (session.status.canOpen)
          ElevatedButton(
            onPressed: busy ? null : () => _confirmLifecycle(open: true),
            child: const Text(AppStrings.openSession),
          ),
        if (session.status.canClose)
          ElevatedButton(
            onPressed: busy ? null : () => _confirmLifecycle(open: false),
            child: const Text(AppStrings.closeSession),
          ),
        if (widget.isAdmin)
          ElevatedButton(
            onPressed: _manageParticipants,
            child: const Text(AppStrings.manageParticipants),
          ),
        if (widget.isAdmin)
          ElevatedButton(
            onPressed: _monitorLive,
            child: const Text(AppStrings.liveMonitoringTitle),
          ),
        ElevatedButton(
          onPressed: _manageScoring,
          child: const Text(AppStrings.scoringReviewTitle),
        ),
        ElevatedButton(
          onPressed: _viewViolations,
          child: const Text(AppStrings.violationAuditTitle),
        ),
      ],
    );
  }

  void _assignClass() {
    final classPublicId = _classPublicIdController.text.trim();
    if (classPublicId.isEmpty) return;
    context.read<SessionDetailBloc>().add(ClassAssignRequested(classPublicId));
    _classPublicIdController.clear();
  }

  void _unassignClass(String classPublicId) {
    context.read<SessionDetailBloc>().add(
      ClassUnassignRequested(classPublicId),
    );
  }

  Future<void> _manageParticipants() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => GetIt.instance<EnrollmentBloc>()),
          BlocProvider(create: (_) => GetIt.instance<ProctorAssignmentBloc>()),
        ],
        child: ParticipantManagementPage(
          sessionPublicId: widget.data.session.publicId,
          loadUsers: GetIt.instance<LoadHostUsers>().call,
        ),
      ),
    ),
  );

  Future<void> _manageScoring() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SessionScoringEntryPage(
        sessionPublicId: widget.data.session.publicId,
        isAdmin: widget.isAdmin,
      ),
    ),
  );

  Future<void> _monitorLive() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LiveProctorEntryPage(
        sessionPublicId: widget.data.session.publicId,
        canControl: false,
      ),
    ),
  );

  Future<void> _viewViolations() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ViolationAuditEntryPage(
        sessionPublicId: widget.data.session.publicId,
      ),
    ),
  );

  Future<void> _confirmLifecycle({required bool open}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.sessionTransitionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              open ? AppStrings.openSession : AppStrings.closeSession,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.read<SessionDetailBloc>().add(
      open ? const SessionOpenRequested() : const SessionCloseRequested(),
    );
  }
}
