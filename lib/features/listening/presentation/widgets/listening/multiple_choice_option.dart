import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class MultipleChoiceOption extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const MultipleChoiceOption({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spacingMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.optionRadioSize,
              height: AppDimensions.optionRadioSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMedium,
                  width: AppDimensions.borderWidthThin,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textMedium,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingMedium),
            RichText(
              text: TextSpan(
                style: AppTextStyles.instruction,
                children: [
                  TextSpan(
                    text: '$label. ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
