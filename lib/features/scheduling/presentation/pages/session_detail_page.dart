import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/session_types.dart';
import '../bloc/session_detail_bloc.dart';
import '../bloc/session_detail_event.dart';
import '../bloc/session_detail_state.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessionDetailTitle)),
      body: BlocBuilder<SessionDetailBloc, SessionDetailState>(
        builder: (context, state) => switch (state) {
          SessionDetailInitial() ||
          SessionDetailLoading() => const LoadingView(),
          SessionDetailData() => _SessionDetailBody(data: state),
          SessionDetailFailure(:final data) when data != null =>
            _SessionDetailBody(data: data, mutationFailed: true),
          SessionDetailFailure() => const Center(
            child: Text(AppStrings.sessionsLoadFailure),
          ),
        },
      ),
    );
  }
}

class _SessionDetailBody extends StatefulWidget {
  const _SessionDetailBody({required this.data, this.mutationFailed = false});
  final SessionDetailData data;
  final bool mutationFailed;

  @override
  State<_SessionDetailBody> createState() => _SessionDetailBodyState();
}

class _SessionDetailBodyState extends State<_SessionDetailBody> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.session.composition
        .map((item) => item.taskType)
        .toSet();
  }

  @override
  void didUpdateWidget(covariant _SessionDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.session.composition != widget.data.session.composition) {
      _selected = widget.data.session.composition
          .map((item) => item.taskType)
          .toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.data.session;
    final busy = widget.data is SessionDetailTransitioning;
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
          AppStrings.compositionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(AppStrings.compositionHint),
        if (widget.data.options.isEmpty)
          const Text(AppStrings.compositionEmpty)
        else
          for (final option in widget.data.options)
            CheckboxListTile(
              value: _selected.contains(option.taskType),
              title: Text(option.title),
              subtitle: Text('${option.taskType} · ${option.section}'),
              onChanged: busy
                  ? null
                  : (selected) => setState(() {
                      if (selected ?? false) {
                        _selected.add(option.taskType);
                      } else {
                        _selected.remove(option.taskType);
                      }
                    }),
            ),
        if (widget.data is SessionDetailConflict)
          const Text(AppStrings.sessionConflict),
        if (widget.data is SessionDetailInvalid)
          Text((widget.data as SessionDetailInvalid).message),
        if (widget.mutationFailed)
          const Text(AppStrings.sessionMutationFailure),
        PrimaryButton(
          label: AppStrings.saveComposition,
          isLoading: busy,
          onPressed: widget.data.options.isEmpty ? null : _saveComposition,
        ),
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
      ],
    );
  }

  void _saveComposition() {
    final selectedOptions = widget.data.options
        .where((option) => _selected.contains(option.taskType))
        .toList(growable: false);
    context.read<SessionDetailBloc>().add(
      SessionCompositionSubmitted(
        SetCompositionInput(
          items: [
            for (var index = 0; index < selectedOptions.length; index++)
              CompositionItemInput(
                taskType: selectedOptions[index].taskType,
                section: selectedOptions[index].section,
                orderIndex: index,
              ),
          ],
        ),
      ),
    );
  }

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
