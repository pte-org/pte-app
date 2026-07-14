import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class AptisTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const AptisTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.loginLabel),
        const SizedBox(height: AppDimensions.spacingXs),
        SizedBox(
          height: AppDimensions.loginInputHeight,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: AppTextStyles.loginInput,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.loginInput.copyWith(
                color: AppColors.loginInputHint,
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.loginInputContentPaddingHorizontal,
                vertical: AppDimensions.loginInputContentPaddingVertical,
              ),
              enabledBorder: _border(AppColors.loginInputBorder),
              focusedBorder: _border(AppColors.bottomBarBackground),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color),
    );
  }
}
