import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';

/// One inline gap's text field, sized to sit inside a `WidgetSpan` without
/// breaking line flow (phase-05 Design Constraints). The
/// `TextEditingController` is owned and disposed by the screen, never by
/// this widget or the cubit.
class FillBlanksInputWidget extends StatelessWidget {
  const FillBlanksInputWidget({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.fillBlanksGapMinWidth,
      child: TextField(
        controller: controller,
        maxLines: 1,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(
            AppDimensions.fillBlanksGapPadding,
          ),
          filled: true,
          fillColor: AppColors.interactiveSelected,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
