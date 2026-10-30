import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

enum ChoiceSelectionMode { single, multiple }

class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.mode,
    required this.onTap,
    this.plain = false,
  });

  final String label;
  final bool selected;
  final ChoiceSelectionMode mode;
  final VoidCallback? onTap;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: plain ? 4 : 18,
            vertical: plain ? 8 : 14,
          ),
          decoration: plain
              ? null
              : BoxDecoration(
                  color: selected
                      ? AppColors.interactiveSelected
                      : AppColors.surface,
                  border: Border.all(
                    color: selected ? AppColors.brandPrimary : AppColors.border,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                ),
          child: Row(
            children: [
              Icon(
                mode == ChoiceSelectionMode.multiple
                    ? (selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                    : (selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                color: selected ? AppColors.brandPrimary : AppColors.outline,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.examAnswer.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
