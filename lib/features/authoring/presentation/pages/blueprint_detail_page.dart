import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/blueprint_types.dart';
import '../bloc/blueprint_detail_bloc.dart';
import '../bloc/blueprint_detail_event.dart';
import '../bloc/blueprint_detail_state.dart';
import 'snapshot_detail_page.dart';

class BlueprintDetailPage extends StatelessWidget {
  const BlueprintDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.blueprintDetailTitle)),
      body: BlocConsumer<BlueprintDetailBloc, BlueprintDetailState>(
        listener: (context, state) {
          if (state is BlueprintPublished) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => SnapshotDetailPage(snapshot: state.snapshot),
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          BlueprintDetailInitial() ||
          BlueprintDetailLoading() => const LoadingView(),
          BlueprintDetailReady(:final blueprint) => _Detail(
            blueprint: blueprint,
            publishing: false,
          ),
          BlueprintPublishing(:final blueprint) => _Detail(
            blueprint: blueprint,
            publishing: true,
          ),
          BlueprintDetailFailure(:final blueprint) when blueprint != null =>
            _Detail(blueprint: blueprint, publishing: false, failed: true),
          BlueprintDetailFailure() => const Center(
            child: Text(AppStrings.blueprintsLoadFailure),
          ),
          BlueprintPublished() => const LoadingView(),
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.blueprint,
    required this.publishing,
    this.failed = false,
  });

  final Blueprint blueprint;
  final bool publishing;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      children: [
        Text(blueprint.name, style: Theme.of(context).textTheme.headlineSmall),
        Text(blueprint.status),
        for (final item in blueprint.items)
          ListTile(
            leading: Text('${item.orderIndex + 1}'),
            title: Text(item.questionPublicId),
            subtitle: Text(item.section),
          ),
        if (failed) const Text(AppStrings.publishFailure),
        PrimaryButton(
          label: AppStrings.publishBlueprint,
          isLoading: publishing,
          onPressed: () => _confirm(context),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.publishConfirmationTitle),
        content: const Text(AppStrings.publishConfirmationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.publish),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<BlueprintDetailBloc>().add(const BlueprintPublishRequested());
  }
}
