import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/data/attempt_audio_cache.dart';
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

  /// The copy downloaded at the start of the attempt, if any, so the image
  /// still shows offline. Null when the cache is not registered (tests) or
  /// this image was not downloaded: it then loads from the network.
  String? _cachedPath() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<AttemptAudioCache>()) return null;
    return getIt<AttemptAudioCache>().localPathFor(imageUrl);
  }

  Widget _errorFallback() {
    return const Center(
      child: Text(
        SpeakingWritingStrings.taskImageLoadErrorLabel,
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cachedPath = _cachedPath();
    return SizedBox(
      height: AppDimensions.taskImageDisplayHeight,
      width: double.infinity,
      child: cachedPath != null
          ? Image.file(
              File(cachedPath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _errorFallback(),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => _errorFallback(),
            ),
    );
  }
}
