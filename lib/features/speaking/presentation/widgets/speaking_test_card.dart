import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/features/speaking/domain/entities/speaking_question.dart';
import 'speaking_header.dart';
import 'speaking_microphone_button.dart';
import 'speaking_progress_dots.dart';
import 'speaking_countdown_timer.dart';
import 'speaking_images_viewer.dart';
import 'speaking_question_renderer.dart';

class SpeakingTestCard extends StatelessWidget {
  final SpeakingQuestion question;
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int> onQuestionSelected;
  final VoidCallback onMicrophonePressed;
  final SpeakingMicState micState;
  final int timeRemaining;
  final int totalTime;
  final String timerLabel;

  const SpeakingTestCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalCount,
    required this.onQuestionSelected,
    required this.onMicrophonePressed,
    required this.micState,
    required this.timeRemaining,
    required this.totalTime,
    required this.timerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.speakingCardMinHeight,
      ),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: const [
          BoxShadow(
            color: AppColors.speakingShadow,
            blurRadius: AppDimensions.speakingCardShadowBlur,
            offset: Offset(0, AppDimensions.speakingCardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        children: [
          const SpeakingHeader(),
          Container(
            height: AppDimensions.speakingHeaderAccentHeight,
            color: AppColors.accentRed,
          ),
          SpeakingCountdownTimer(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            label: timerLabel,
          ),
          Expanded(
            child: _SpeakingPromptBody(
              question: question,
              micState: micState,
              onMicrophonePressed: onMicrophonePressed,
            ),
          ),
          _SpeakingCardFooter(
            partLabel: question.partLabel,
            currentIndex: currentIndex,
            totalCount: totalCount,
            onQuestionSelected: onQuestionSelected,
          ),
        ],
      ),
    );
  }
}

class _SpeakingPromptBody extends StatelessWidget {
  final SpeakingQuestion question;
  final SpeakingMicState micState;
  final VoidCallback onMicrophonePressed;

  const _SpeakingPromptBody({
    required this.question,
    required this.micState,
    required this.onMicrophonePressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPart3 = question.imageUrls != null && question.imageUrls!.length == 2;
    final bool isPart4 = question.subPrompts != null && question.subPrompts!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final double verticalPadding = height < 160 ? 8.0 : (height < 240 ? 16.0 : AppDimensions.speakingBodyPaddingVertical);
        final double horizontalPadding = width < 800 ? 20.0 : AppDimensions.speakingBodyPaddingHorizontal;
        final double bodyGap = width < 800 ? 20.0 : AppDimensions.speakingBodyGap;
        final double imageLabelGap = width < 800 ? 12.0 : AppDimensions.speakingImageLabelGap;

        final double micSize = height < 160 ? 56.0 : (height < 220 ? 72.0 : AppDimensions.speakingMicButtonSize);
        final double micIconSize = height < 160 ? 24.0 : (height < 220 ? 32.0 : AppDimensions.speakingMicIconSize);
        final double micBorderWidth = height < 160 ? 2.0 : AppDimensions.speakingMicBorderWidth;

        double imageWidth = AppDimensions.speakingPromptImageWidth;
        double imageHeight = AppDimensions.speakingPromptImageHeight;

        if (isPart3) {
          imageHeight = height < 160 ? 60.0 : (height < 220 ? 80.0 : 100.0);
          imageWidth = imageHeight * 1.4;
        } else if (question.showsImage) {
          imageHeight = height < 160 ? 70.0 : (height < 220 ? 90.0 : 120.0);
          imageWidth = imageHeight * 1.4;
        }

        final bool showLabelText = height >= 140;

        return Container(
          width: double.infinity,
          color: AppColors.speakingPanelBackground,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeakingImagesViewer(
                isPart3: isPart3,
                showsImage: question.showsImage,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                imageLabelGap: imageLabelGap,
                showLabelText: showLabelText,
              ),
              SpeakingQuestionRenderer(
                question: question,
                isPart3: isPart3,
                isPart4: isPart4,
                width: width,
                height: height,
              ),
              SizedBox(width: bodyGap),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpeakingMicrophoneButton(
                    state: micState,
                    onPressed: onMicrophonePressed,
                    dimension: micSize,
                    iconSize: micIconSize,
                    borderWidth: micBorderWidth,
                  ),
                  if (height >= 180) ...[
                    const SizedBox(height: AppDimensions.spacingSmall),
                    Text(
                      micState == SpeakingMicState.recording
                          ? AppStrings.speakingRecording
                          : (micState == SpeakingMicState.completed
                              ? AppStrings.speakingCompleted
                              : AppStrings.speakingClickToRecord),
                      style: AppTextStyles.speakingFooterLabel.copyWith(
                        fontSize: 9,
                        color: micState == SpeakingMicState.recording
                            ? Colors.red
                            : (micState == SpeakingMicState.completed ? Colors.green : AppColors.textMedium),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeakingCardFooter extends StatelessWidget {
  final String partLabel;
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int> onQuestionSelected;

  const _SpeakingCardFooter({
    required this.partLabel,
    required this.currentIndex,
    required this.totalCount,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.speakingFooterHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(partLabel, style: AppTextStyles.speakingFooterLabel),
          SpeakingProgressDots(
            currentIndex: currentIndex,
            totalCount: totalCount,
            onDotSelected: onQuestionSelected,
          ),
        ],
      ),
    );
  }
}
