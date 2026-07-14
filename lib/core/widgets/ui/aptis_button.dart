import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class AptisButton extends StatelessWidget {
  final String text;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final double? height;
  final Color? color;
  final IconData? icon;

  const AptisButton({
    super.key,
    required this.text,
    required this.isSubmitting,
    required this.onSubmit,
    this.height,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? AppDimensions.loginButtonHeight,
      width: double.infinity,
      child: Material(
        color: color ?? AppColors.bottomBarBackground,
        child: InkWell(
          onTap: isSubmitting ? null : onSubmit,
          child: Center(
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: AppDimensions.loginButtonIconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimensions.borderWidthThin,
                      color: AppColors.textDark,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: AppTextStyles.loginButton,
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: AppDimensions.spacingSmall),
                        Icon(
                          icon,
                          size: AppDimensions.loginButtonIconSize,
                          color: AppColors.textDark,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
