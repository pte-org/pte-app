import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class ExamTextarea extends StatelessWidget {
  const ExamTextarea({
    super.key,
    required this.controller,
    this.minLines = 8,
    this.maxLines,
    this.expands = false,
    this.enabled = true,
    this.labelText,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final bool enabled;
  final String? labelText;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      expands: expands,
      enabled: enabled,
      onChanged: onChanged,
      style: AppTypography.bodyPassage.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        errorText: errorText,
        labelText: labelText,
        contentPadding: const EdgeInsets.all(12),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
    );
  }
}
