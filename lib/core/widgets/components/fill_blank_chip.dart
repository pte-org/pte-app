import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class FillBlankChip extends StatelessWidget {
  const FillBlankChip({
    super.key,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: ActionChip(
        label: Text(label),
        onPressed: enabled ? onTap : null,
        backgroundColor: selected
            ? AppColors.interactiveSelected
            : AppColors.surfaceSubtle,
        disabledColor: AppColors.inactive,
        side: BorderSide(
          color: selected ? AppColors.brandPrimary : AppColors.border,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        labelStyle: AppTypography.bodyRegular.copyWith(
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
      ),
    );
  }
}
