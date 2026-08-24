import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/blueprint_types.dart';

class SnapshotDetailPage extends StatelessWidget {
  const SnapshotDetailPage({super.key, required this.snapshot});

  final ExamSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.snapshotTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        children: [
          Text(snapshot.name, style: Theme.of(context).textTheme.headlineSmall),
          Text('${AppStrings.snapshotVersion} ${snapshot.version}'),
          Text(
            '${AppStrings.snapshotSource}: ${snapshot.sourceBlueprintPublicId}',
          ),
          const Divider(),
          for (final item in snapshot.items)
            ListTile(
              leading: Text('${item.orderIndex + 1}'),
              title: Text(item.title),
              subtitle: Text('${item.section} · ${item.taskType.wireName}'),
            ),
        ],
      ),
    );
  }
}
