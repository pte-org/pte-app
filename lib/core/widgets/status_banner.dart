import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Icon + title + message layout for a full-body steady-state or error
/// screen (e.g. "waiting for publish," "something went wrong"). Shared so
/// every such screen looks structurally consistent instead of each
/// feature reimplementing its own icon/title/message column.
///
/// [isError] swaps the icon badge from the default blue to a red tint —
/// the one visual distinction between a benign steady-state ("still
/// waiting") and an actual failure, without either caller needing to know
/// the badge's colors.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.icon, required this.title, required this.message, this.isError = false});

  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accentColor = isError ? AppColors.error : AppColors.primary;
    final badgeColor = isError ? AppColors.statusBannerErrorIconBackground : AppColors.statusBannerIconBackground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMedium * 3),
      child: Column(
        children: [
          Container(
            width: AppDimensions.statusBannerIconBadgeSize,
            height: AppDimensions.statusBannerIconBadgeSize,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            child: Icon(icon, color: accentColor, size: AppDimensions.statusBannerIconSize),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.spacingMedium / 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMedium * 2),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
