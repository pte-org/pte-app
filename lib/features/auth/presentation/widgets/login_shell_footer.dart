import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class LoginShellFooter extends StatelessWidget {
  const LoginShellFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.loginFooterHeight,
      color: AppColors.loginFooterBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.loginFooterPaddingHorizontal,
      ),
      child: const Row(
        children: [
          Text(AppStrings.loginCopyright, style: AppTextStyles.loginFooter),
          Spacer(),
          Text(AppStrings.loginPrivacyPolicy, style: AppTextStyles.loginFooter),
          SizedBox(width: AppDimensions.loginFooterLinkGap),
          Text(AppStrings.loginTermsOfUse, style: AppTextStyles.loginFooter),
        ],
      ),
    );
  }
}
