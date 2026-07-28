import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../host_users/domain/host_user.dart';
import '../bloc/participant_command_bloc.dart';
import '../bloc/participant_command_event.dart';
import '../bloc/participant_command_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef LoadParticipantUsers = Future<List<HostUser>> Function();
typedef ParticipantCommand =
    Future<void> Function(String sessionPublicId, String userPublicId);

class ParticipantManagementPage extends StatefulWidget {
  const ParticipantManagementPage({
    super.key,
    required this.sessionPublicId,
    required this.loadUsers,
    this.onEnroll,
    this.onAssign,
  });

  final String sessionPublicId;
  final LoadParticipantUsers loadUsers;
  final ParticipantCommand? onEnroll;
  final ParticipantCommand? onAssign;

  @override
  State<ParticipantManagementPage> createState() =>
      _ParticipantManagementPageState();
}

class _ParticipantManagementPageState extends State<ParticipantManagementPage> {
  late Future<List<HostUser>> _users;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _users = widget.loadUsers();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.participantManagementTitle)),
    body: FutureBuilder<List<HostUser>>(
      future: _users,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _users = widget.loadUsers()),
              child: const Text(AppStrings.retry),
            ),
          );
        }
        final users = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          children: [
            _section(
              AppStrings.studentsTitle,
              users.where((user) => user.isStudent),
              AppStrings.enrollStudent,
              widget.onEnroll ?? _enroll,
            ),
            _section(
              AppStrings.proctorsTitle,
              users.where((user) => user.isProctor),
              AppStrings.assignProctor,
              widget.onAssign ?? _assign,
            ),
          ],
        );
      },
    ),
  );

  Widget _section(
    String title,
    Iterable<HostUser> users,
    String actionLabel,
    ParticipantCommand command,
  ) {
    final eligible = users.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (eligible.isEmpty)
          const Text(AppStrings.noEligibleUsers)
        else
          for (final user in eligible)
            ListTile(
              title: Text(user.fullName),
              subtitle: Text(user.email),
              trailing: TextButton(
                onPressed: _submitting
                    ? null
                    : () => _run(command, user.publicId),
                child: Text(actionLabel),
              ),
            ),
      ],
    );
  }

  Future<void> _run(ParticipantCommand command, String userPublicId) async {
    if (_submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.participantConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _submitting = true);
    try {
      await command(widget.sessionPublicId, userPublicId);
      if (mounted) _message(AppStrings.participantCommandSuccess);
    } catch (_) {
      if (mounted) _message(AppStrings.participantCommandFailure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _enroll(String sessionId, String userId) => _dispatch(
    context.read<EnrollmentBloc>(),
    EnrollmentSubmitted(sessionId, userId),
  );

  Future<void> _assign(String sessionId, String userId) => _dispatch(
    context.read<ProctorAssignmentBloc>(),
    ProctorAssignmentSubmitted(sessionId, userId),
  );

  Future<void> _dispatch(
    Bloc<ParticipantCommandEvent, ParticipantCommandState> bloc,
    ParticipantCommandEvent event,
  ) async {
    bloc.add(event);
    final state = await bloc.stream.firstWhere(
      (value) => value is ParticipantSuccess || value is ParticipantFailure,
    );
    if (state is ParticipantFailure) throw state.error;
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
