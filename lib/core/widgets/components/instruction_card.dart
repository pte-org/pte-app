import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class InstructionCard extends StatelessWidget {
  const InstructionCard({
    super.key,
    required this.instruction,
    this.metadata = const [],
  });

  final String instruction;
  final List<String> metadata;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.brandPrimary,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: AppTypography.instructionBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacingSm),
                  Wrap(
                    spacing: AppDimensions.spacingLg,
                    runSpacing: AppDimensions.spacingXs,
                    children: [
                      for (final item in metadata)
                        Text(
                          item,
                          style: AppTypography.labelMeta.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
