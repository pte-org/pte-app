import 'package:flutter/material.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/task_type_meta.dart';
import '../../constants/app_typography.dart';
import 'exam_task_frame.dart';
import 'exam_template_frame.dart';

bool usesStatusAudioPanels(String taskType) =>
    TaskTypeCodes.canonicalize(taskType) ==
        TaskTypeCodes.summarizeGroupDiscussion ||
    TaskTypeCodes.canonicalize(taskType) == TaskTypeCodes.respondToASituation;

/// Common body composition for the two status-style Speaking tasks.
class StatusSpeakingTaskFrame extends StatelessWidget {
  const StatusSpeakingTaskFrame({
    super.key,
    required this.taskType,
    required this.title,
    required this.instruction,
    required this.panels,
    this.promptText,
    this.image,
  });
  final String taskType;
  final String title;
  final String instruction;
  final String? promptText;
  final Widget? image;
  final Widget panels;

  @override
  Widget build(BuildContext context) {
    if (TaskTypeCodes.canonicalize(taskType) ==
        TaskTypeCodes.summarizeGroupDiscussion) {
      return ExamTemplateFrame(
        title: title,
        instruction: instruction,
        layout: ExamTemplateLayout.split,
        contentMaxWidth: AppDimensions.statusSpeakingContentMaxWidth,
        stimulus: image ?? const _DiscussionIllustration(),
        response: panels,
      );
    }
    return ExamTaskFrame(
      title: title,
      instruction: instruction,
      contentMaxWidth: AppDimensions.statusSpeakingContentMaxWidth,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (promptText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppDimensions.spacingXl),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.situationPassageMaxWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    promptText!,
                    textAlign: TextAlign.left,
                    style: AppTypography.bodyPassage,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
          ],
          panels,
        ],
      ),
    );
  }
}

/// Local task illustration, independent of question media and network access.
class _DiscussionIllustration extends StatelessWidget {
  const _DiscussionIllustration();
  @override
  Widget build(BuildContext context) => const Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: AppDimensions.discussionIllustrationSize,
        height: AppDimensions.discussionIllustrationSize,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_rounded,
              size: AppDimensions.discussionBubbleSize,
              color: AppColors.textPrimary,
            ),
            Icon(
              Icons.groups_rounded,
              size: AppDimensions.discussionPeopleSize,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    ),
  );
}
