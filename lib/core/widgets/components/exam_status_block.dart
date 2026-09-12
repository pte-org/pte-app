import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

enum ExamStatusKind { neutral, success, warning, error }

class ExamStatusBlock extends StatelessWidget {
  const ExamStatusBlock({
    super.key,
    required this.title,
    this.message,
    this.kind = ExamStatusKind.neutral,
  });

  final String title;
  final String? message;
  final ExamStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.foreground),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(colors.icon, color: colors.foreground, size: 20),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (message != null)
                  Text(
                    message!,
                    style: AppTypography.bodyRegular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({Color background, Color foreground, IconData icon}) get _colors {
    return switch (kind) {
      ExamStatusKind.success => (
        background: AppColors.successContainer,
        foreground: AppColors.success,
        icon: Icons.check_circle_outline,
      ),
      ExamStatusKind.warning => (
        background: AppColors.warningBackground,
        foreground: AppColors.warningIcon,
        icon: Icons.warning_amber_outlined,
      ),
      ExamStatusKind.error => (
        background: AppColors.errorContainer,
        foreground: AppColors.error,
        icon: Icons.error_outline,
      ),
      ExamStatusKind.neutral => (
        background: AppColors.surfaceSubtle,
        foreground: AppColors.brandPrimary,
        icon: Icons.info_outline,
      ),
    };
  }
}
