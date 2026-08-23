import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// Purely presentational task-image widget — takes an already resolved
/// [imageUrl] as a prop, no BLoC/context reads of its own, so it's
/// trivially testable in isolation and reusable (matches
/// `RecordedAnswerStatusCard`'s style). Renders a real `Image.network`
/// (Flutter SDK built-in, no new dependency) inside a bounded height so
/// [loadingBuilder]'s `CircularProgressIndicator` can lay out before the
/// real image's intrinsic size is known. [errorBuilder] never rethrows —
/// a failed load shows a graceful fallback label instead of crashing.
class TaskImageDisplay extends StatelessWidget {
  const TaskImageDisplay({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.taskImageDisplayHeight,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              SpeakingWritingStrings.taskImageLoadErrorLabel,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          );
        },
      ),
    );
  }
}
