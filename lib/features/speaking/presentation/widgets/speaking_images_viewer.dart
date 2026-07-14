import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'speaking_prompt_art.dart';

class SpeakingImagesViewer extends StatelessWidget {
  final bool isPart3;
  final bool showsImage;
  final double imageWidth;
  final double imageHeight;
  final double imageLabelGap;
  final bool showLabelText;

  const SpeakingImagesViewer({
    super.key,
    required this.isPart3,
    required this.showsImage,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageLabelGap,
    required this.showLabelText,
  });

  @override
  Widget build(BuildContext context) {
    if (isPart3) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeakingPromptArt(
                width: imageWidth,
                height: imageHeight,
              ),
              if (showLabelText) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  AppStrings.speakingImageA,
                  style: AppTextStyles.speakingFooterLabel.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: imageWidth < 130 ? 10 : 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeakingPromptArt(
                width: imageWidth,
                height: imageHeight,
              ),
              if (showLabelText) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  AppStrings.speakingImageB,
                  style: AppTextStyles.speakingFooterLabel.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: imageWidth < 130 ? 10 : 12,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(width: imageLabelGap),
        ],
      );
    } else if (showsImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpeakingPromptArt(
            width: imageWidth,
            height: imageHeight,
          ),
          SizedBox(width: imageLabelGap),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
