import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

/// Brand-outlined companion to `PrimaryButton` for the secondary action in a
/// pair (Previous, "Use a different exam code", ...), so no call site falls
/// back to the Material default outlined style.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
        ),
        foregroundColor: AppColors.brandPrimary,
        disabledForegroundColor: AppColors.textMuted,
        side: const BorderSide(color: AppColors.brandPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.radiusDefault),
          ),
        ),
        textStyle: AppTypography.bodyBold,
      ),
      child: Text(label),
    );
  }
}
