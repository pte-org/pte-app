import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

/// Controllers belong to the screen; TextField owns its focus lifecycle.
class FillBlanksInputWidget extends StatelessWidget {
  const FillBlanksInputWidget({
    super.key,
    required this.controller,
    this.width = AppDimensions.listeningBlankWidth,
  });
  final TextEditingController controller;
  final double width;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: AppColors.border),
    );
    return SizedBox(
      width: width,
      height: AppDimensions.listeningBlankHeight,
      child: TextField(
        controller: controller,
        maxLines: 1,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [FilteringTextInputFormatter.deny(',')],
        textAlign: TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        textDirection: TextDirection.ltr,
        style: AppTypography.examAnswer,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(
              color: AppColors.brandPrimary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
