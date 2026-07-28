import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/live_proctor_types.dart';
import '../bloc/live_proctor_bloc.dart';
import '../bloc/live_proctor_event.dart';
import '../bloc/live_proctor_state.dart';

class LiveProctorEntryPage extends StatelessWidget {
  const LiveProctorEntryPage({
    required this.sessionPublicId,
    required this.canControl,
    super.key,
  });

  final String sessionPublicId;
  final bool canControl;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.instance<LiveProctorBloc>()
      ..add(
        LiveProctorStarted(
          sessionPublicId: sessionPublicId,
          canControl: canControl,
        ),
      ),
    child: LiveProctorPage(canControl: canControl),
  );
}

class LiveProctorPage extends StatefulWidget {
  const LiveProctorPage({required this.canControl, super.key});

  final bool canControl;

  @override
  State<LiveProctorPage> createState() => _LiveProctorPageState();
}

class _LiveProctorPageState extends State<LiveProctorPage> {
  final _attemptController = TextEditingController();
  final _extraSecondsController = TextEditingController(text: '300');
  final _detailController = TextEditingController();
  ViolationType _violationType = ViolationType.tabSwitch;

  @override
  void dispose() {
    _attemptController.dispose();
    _extraSecondsController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LiveProctorBloc, LiveProctorState>(
    builder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.liveMonitoringTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${AppStrings.liveConnectionLabel}: '
            '${state.status.name}',
          ),
          if (!widget.canControl) const Text(AppStrings.liveReadOnlyNotice),
          if (state.message != null) Text(state.message!),
          if (state.status == LiveProctorStatus.reconnectFailed)
            ElevatedButton(
              onPressed: () => context.read<LiveProctorBloc>().add(
                const LiveReconnectRequested(),
              ),
              child: const Text(AppStrings.liveReconnect),
            ),
          if (widget.canControl) ...[
            TextField(
              controller: _attemptController,
              decoration: const InputDecoration(
                labelText: AppStrings.liveAttemptIdLabel,
              ),
            ),
            TextField(
              controller: _extraSecondsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.liveExtraSecondsLabel,
              ),
            ),
            ElevatedButton(
              onPressed: state.commandPending || state.proctorSession == null
                  ? null
                  : () => _confirmCommand(ProctorCommandType.extendTime),
              child: const Text(AppStrings.liveExtendTime),
            ),
            ElevatedButton(
              onPressed: state.commandPending || state.proctorSession == null
                  ? null
                  : () => _confirmCommand(ProctorCommandType.forceSubmit),
              child: const Text(AppStrings.liveForceSubmit),
            ),
            DropdownButtonFormField<ViolationType>(
              initialValue: _violationType,
              items: [
                for (final type in ViolationType.values)
                  DropdownMenuItem(value: type, child: Text(type.wireName)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _violationType = value);
                }
              },
              decoration: const InputDecoration(
                labelText: AppStrings.violationTypeLabel,
              ),
            ),
            TextField(
              controller: _detailController,
              decoration: const InputDecoration(
                labelText: AppStrings.violationDetailLabel,
              ),
            ),
            ElevatedButton(
              onPressed: state.proctorSession == null || state.violationPending
                  ? null
                  : _flagViolation,
              child: const Text(AppStrings.liveFlagViolation),
            ),
          ],
          const Divider(),
          Text(
            AppStrings.liveViolationsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (state.violations.isEmpty)
            const Text(AppStrings.violationAuditEmpty)
          else
            for (final violation in state.violations)
              ListTile(
                title: Text(violation.type.wireName),
                subtitle: Text(
                  '${violation.attemptPublicId}\n'
                  '${violation.detail ?? ''}',
                ),
                trailing: Text('#${violation.sequenceNo}'),
              ),
        ],
      ),
    ),
  );

  Future<void> _confirmCommand(ProctorCommandType type) async {
    final attemptId = _attemptController.text.trim();
    if (attemptId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.liveCommandConfirmation),
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
    context.read<LiveProctorBloc>().add(
      ProctorCommandRequested(
        attemptPublicId: attemptId,
        commandType: type,
        extraSeconds: type == ProctorCommandType.extendTime
            ? int.tryParse(_extraSecondsController.text)
            : null,
      ),
    );
  }

  Future<void> _flagViolation() async {
    final attemptId = _attemptController.text.trim();
    if (attemptId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.liveViolationConfirmation),
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
    context.read<LiveProctorBloc>().add(
      ViolationFlagRequested(
        attemptPublicId: attemptId,
        violationType: _violationType,
        detail: _detailController.text.trim(),
      ),
    );
  }
}
