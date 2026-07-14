import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDots(),
        const SizedBox(width: AppDimensions.brandDotGap),
        const Text(
          AppStrings.brandBritishCouncil,
          textAlign: TextAlign.center,
          style: AppTextStyles.brandCouncil,
        ),
        const SizedBox(width: AppDimensions.brandCouncilAptisGap),
        _buildAptisText(),
      ],
    );
  }

  Widget _buildDots() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        2,
        (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            4,
            (_) => Container(
              width: AppDimensions.dotSize,
              height: AppDimensions.dotSize,
              margin: const EdgeInsets.all(AppDimensions.dotMargin),
              decoration: const BoxDecoration(
                color: AppColors.bottomBarBackground,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAptisText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppStrings.brandAptis, style: AppTextStyles.brandAptis),
        Text(
          AppStrings.brandAptisTagline,
          style: AppTextStyles.brandAptisTagline,
        ),
      ],
    );
  }
}
