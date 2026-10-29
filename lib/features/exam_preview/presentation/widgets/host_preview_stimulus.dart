import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/components/audio_stimulus_player.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'preview_media_status.dart';

class HostPreviewStimulus extends StatelessWidget {
  const HostPreviewStimulus({
    super.key,
    required this.model,
    this.onAudioPressed,
  });

  final PreviewTaskUiModel model;
  final VoidCallback? onAudioPressed;

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    for (final part in model.stimulus.parts) {
      parts.add(_part(part));
      if (part != model.stimulus.parts.last) {
        parts.add(const SizedBox(height: AppDimensions.spacingMd));
      }
    }
    return parts.isEmpty
        ? const ExamStatusBlock(
            title: ExamPreviewStrings.noStimulusTitle,
            message: ExamPreviewStrings.noStimulusMessage,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: parts,
          );
  }

  Widget _part(StimulusPart part) {
    return switch (part.kind) {
      StimulusPartKind.audio => AudioStimulusPlayer(
        label: ExamPreviewStrings.audioLabel,
        onPressed: onAudioPressed,
      ),
      StimulusPartKind.image => ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDimensions.spacingXs),
        ),
        child: Image.network(
          part.content,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const PreviewMediaStatus(
                title: ExamPreviewStrings.imageErrorTitle,
                message: ExamPreviewStrings.imageErrorMessage,
                isError: true,
              ),
        ),
      ),
      StimulusPartKind.passage ||
      StimulusPartKind.text ||
      StimulusPartKind.transcript => SelectableText(
        part.content,
        style: AppTypography.bodyPassage.copyWith(color: AppColors.textPrimary),
      ),
    };
  }
}
