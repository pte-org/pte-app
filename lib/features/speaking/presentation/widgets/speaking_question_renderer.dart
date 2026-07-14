import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/features/speaking/domain/entities/speaking_question.dart';

class SpeakingQuestionRenderer extends StatelessWidget {
  final SpeakingQuestion question;
  final bool isPart3;
  final bool isPart4;
  final double width;
  final double height;

  const SpeakingQuestionRenderer({
    super.key,
    required this.question,
    required this.isPart3,
    required this.isPart4,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (question.showsImage || isPart3)
              ? AppDimensions.speakingImagePromptTextWidth
              : AppDimensions.speakingQuestionTextWidth,
        ),
        child: isPart4
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    question.prompt,
                    style: AppTextStyles.speakingPrompt.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: (width < 800 || height < 200) ? 12 : 14,
                    ),
                  ),
                  if (height >= 180) ...[
                    const SizedBox(height: AppDimensions.spacingMedium),
                    ...question.subPrompts!.asMap().entries.map((entry) {
                      final int index = entry.key + 1;
                      final String text = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '$index. $text',
                          style: AppTextStyles.speakingPrompt.copyWith(
                            fontSize: width < 800 ? 11 : 13,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              )
            : Text(
                question.prompt,
                style: AppTextStyles.speakingPrompt.copyWith(
                  fontSize: (width < 800 || height < 200) ? 12 : 15,
                ),
              ),
      ),
    );
  }
}
