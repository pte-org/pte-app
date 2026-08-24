import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/blueprint_types.dart';
import '../bloc/blueprint_builder_bloc.dart';
import '../bloc/blueprint_detail_bloc.dart';
import '../bloc/blueprint_detail_event.dart';
import '../bloc/blueprint_list_bloc.dart';
import '../bloc/blueprint_list_event.dart';
import '../bloc/blueprint_list_state.dart';
import 'blueprint_builder_page.dart';
import 'blueprint_detail_page.dart';

class BlueprintListPage extends StatelessWidget {
  const BlueprintListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<BlueprintListBloc>()
            ..add(const BlueprintListRequested()),
      child: const _BlueprintListView(),
    );
  }
}

class _BlueprintListView extends StatelessWidget {
  const _BlueprintListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.blueprintsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.createBlueprint),
      ),
      body: BlocBuilder<BlueprintListBloc, BlueprintListState>(
        builder: (context, state) => switch (state) {
          BlueprintListInitial() ||
          BlueprintListLoading() => const LoadingView(),
          BlueprintListEmpty() => const Center(
            child: Text(AppStrings.blueprintsEmpty),
          ),
          BlueprintListFailure() => _FailureView(
            onRetry: () => context.read<BlueprintListBloc>().add(
              const BlueprintListRequested(),
            ),
          ),
          BlueprintListLoaded(:final blueprints) => _Blueprints(
            blueprints: blueprints,
          ),
        },
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final created = await Navigator.of(context).push<Blueprint>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<BlueprintBuilderBloc>(),
          child: const BlueprintBuilderPage(),
        ),
      ),
    );
    if (!context.mounted || created == null) return;
    context.read<BlueprintListBloc>().add(const BlueprintListRequested());
  }
}

class _Blueprints extends StatelessWidget {
  const _Blueprints({required this.blueprints});
  final List<Blueprint> blueprints;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      itemCount: blueprints.length,
      itemBuilder: (_, index) {
        final blueprint = blueprints[index];
        return Card(
          child: ListTile(
            title: Text(blueprint.name),
            subtitle: Text('${blueprint.status} · ${blueprint.items.length}'),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      GetIt.instance<BlueprintDetailBloc>()
                        ..add(BlueprintDetailRequested(blueprint.publicId)),
                  child: const BlueprintDetailPage(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppStrings.blueprintsLoadFailure),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
