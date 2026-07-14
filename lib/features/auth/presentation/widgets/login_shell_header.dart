import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/widgets/exam/brand_logo.dart';

class LoginShellHeader extends StatelessWidget {
  const LoginShellHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.loginHeaderHeight,
      color: AppColors.topBarBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.loginHeaderPaddingHorizontal,
        ),
        child: Row(
          children: [
            const BrandLogo(),
            const Spacer(),
            const Icon(
              Icons.power_settings_new,
              size: AppDimensions.loginHeaderIconSize,
              color: AppColors.textMedium,
            ),
            const SizedBox(width: AppDimensions.loginHeaderActionGap),
            const Icon(
              Icons.language,
              size: AppDimensions.loginHeaderIconSize,
              color: AppColors.logoGray,
            ),
          ],
        ),
      ),
    );
  }
}
