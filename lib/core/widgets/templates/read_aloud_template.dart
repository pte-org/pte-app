import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'exam_task_frame.dart';

/// Exam-like body shared by candidate Read Aloud and host preview.
/// Chrome and recording/navigation behavior remain owned by the caller.
class ReadAloudTemplate extends StatelessWidget {
  const ReadAloudTemplate({
    super.key,
    required this.title,
    required this.instruction,
    required this.recorder,
    required this.passage,
  });

  final String title;
  final String instruction;
  final Widget recorder;
  final Widget passage;

  @override
  Widget build(BuildContext context) {
    return ExamTaskFrame(
      title: title,
      instruction: instruction,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.readAloudRecorderMaxWidth,
              ),
              child: recorder,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          DefaultTextStyle.merge(
            style: AppTypography.bodyPassage.copyWith(
              color: AppColors.textPrimary,
            ),
            child: passage,
          ),
        ],
      ),
    );
  }
}
