import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class SubheaderBanner extends StatelessWidget {
  const SubheaderBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.reference,
    this.skills = const [],
  });

  final String title;
  final String? subtitle;
  final String? reference;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.labelMeta.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (reference != null)
            Text(
              reference!,
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          if (skills.isNotEmpty) ...[
            const SizedBox(width: AppDimensions.spacingMd),
            Text(
              skills.join(' · '),
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
