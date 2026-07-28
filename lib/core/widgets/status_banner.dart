import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

/// Icon + title + message layout for a full-body steady-state or error
/// screen (e.g. "waiting for publish," "something went wrong"). Shared so
/// every such screen looks structurally consistent instead of each
/// feature reimplementing its own icon/title/message column.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMedium * 4),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spacingMedium / 2),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
