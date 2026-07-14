import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/widgets/exam/brand_logo.dart';

class SpeakingHeader extends StatelessWidget {
  const SpeakingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppDimensions.speakingHeaderHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.speakingHeaderPaddingHorizontal,
        ),
        child: Row(
          children: [
            BrandLogo(),
          ],
        ),
      ),
    );
  }
}
