import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

/// The text-field look shared by every auth screen (sign-in and the forced
/// password change), so the two cannot drift apart.
InputDecoration authFieldDecoration(String label, {String? helperText}) {
  return InputDecoration(
    labelText: label,
    helperText: helperText,
    helperMaxLines: 2,
    helperStyle: const TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 10,
      height: 1.25,
      color: AppColors.loginMutedText,
    ),
    labelStyle: const TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.loginText,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.loginFieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.loginFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    errorStyle: const TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 10,
      height: 1.2,
      color: AppColors.error,
    ),
  );
}
