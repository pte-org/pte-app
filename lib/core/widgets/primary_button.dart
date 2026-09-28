import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

/// Standard elevated button with a built-in loading spinner — every
/// primary action across the app (advance, submit, retry) uses this
/// instead of a bare `ElevatedButton` reimplemented per call site.
/// [onPressed] is ignored (button disabled) while [isLoading] is true,
/// regardless of what's passed in.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ?? _defaultStyle(),
      child: isLoading
          ? SizedBox(
              width: AppDimensions.advanceButtonSpinnerSize,
              height: AppDimensions.advanceButtonSpinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: AppDimensions.advanceButtonSpinnerStrokeWidth,
                color: isLoading ? AppColors.textMuted : AppColors.onPrimary,
              ),
            )
          : Text(label),
    );
  }

  ButtonStyle _defaultStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(0, AppDimensions.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      backgroundColor: AppColors.brandPrimary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: AppColors.inactive,
      disabledForegroundColor: AppColors.textMuted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusDefault),
        ),
      ),
      textStyle: AppTypography.bodyBold,
    );
  }
}
