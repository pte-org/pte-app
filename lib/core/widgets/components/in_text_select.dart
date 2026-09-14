import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class InTextSelect extends StatelessWidget {
  const InTextSelect({
    super.key,
    required this.options,
    this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: [
        for (final option in options)
          DropdownMenuItem<String>(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
      style: AppTypography.bodyRegular.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
    );
  }
}
