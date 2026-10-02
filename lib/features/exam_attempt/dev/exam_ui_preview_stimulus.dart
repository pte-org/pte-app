import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/components/audio_stimulus_player.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/components/in_text_select.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/dev/fixture_image.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';

class ExamUiPreviewStimulus extends StatefulWidget {
  const ExamUiPreviewStimulus({
    super.key,
    required this.model,
    this.audioLabel,
    this.onAudioPressed,
    this.audioPlaying = false,
    this.audioProgress = 0,
  });

  final ExamTaskUiModel model;
  final String? audioLabel;
  final VoidCallback? onAudioPressed;
  final bool audioPlaying;
  final double audioProgress;

  @override
  State<ExamUiPreviewStimulus> createState() => _ExamUiPreviewStimulusState();
}

class _ExamUiPreviewStimulusState extends State<ExamUiPreviewStimulus> {
  final Map<int, TextEditingController> _blankControllers = {};
  final Map<int, String?> _blankSelections = {};

  @override
  void dispose() {
    for (final controller in _blankControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final parts = <Widget>[];
    for (final part in model.stimulus.parts) {
      parts.add(switch (part.kind) {
        StimulusPartKind.audio => AudioStimulusPlayer(
          label: widget.audioLabel ?? 'Offline audio fixture',
          progress: widget.audioProgress,
          onPressed: widget.onAudioPressed,
          playing: widget.audioPlaying,
        ),
        StimulusPartKind.image => PreviewFixtureImage(label: part.content),
        StimulusPartKind.passage ||
        StimulusPartKind.text ||
        StimulusPartKind.transcript =>
          model.meta.family == TaskTemplateFamily.fillBlanks
              ? _blankPrompt(part.content)
              : SelectableText(
                  part.content,
                  style: AppTypography.bodyPassage.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
      });
      if (parts.length < model.stimulus.parts.length) {
        parts.add(const SizedBox(height: AppDimensions.spacingMd));
      }
    }
    return parts.isEmpty
        ? const ExamStatusBlock(
            title: 'No additional stimulus',
            message: 'This task starts with the response instruction.',
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: parts,
          );
  }

  Widget _blankPrompt(String content) {
    final segments = parseBlankPrompt(content);
    return Text.rich(
      TextSpan(
        children: [for (final segment in segments) _blankSegment(segment)],
      ),
    );
  }

  InlineSpan _blankSegment(PromptSegment segment) {
    if (segment is PromptTextSegment) return TextSpan(text: segment.text);

    final gapIndex = (segment as PromptGapSegment).gapIndex;
    final groups = widget.model.blankGroups.where(
      (candidate) => candidate.blankIndex == gapIndex,
    );
    if (groups.isNotEmpty) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SizedBox(
          width: 132,
          child: InTextSelect(
            options: [for (final option in groups.first.options) option.text],
            value: _blankSelections[gapIndex],
            onChanged: (value) =>
                setState(() => _blankSelections[gapIndex] = value),
          ),
        ),
      );
    }
    if (widget.model.taskType == TaskTypeCodes.fillInTheBlanksTypeIn) {
      final controller = _blankControllers.putIfAbsent(
        gapIndex,
        TextEditingController.new,
      );
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SizedBox(
          width: 132,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Blank ${gapIndex + 1}',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingSm,
                vertical: AppDimensions.spacingXs,
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
        ),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 96,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.all(Radius.circular(3)),
        ),
        child: Text('Blank ${gapIndex + 1}'),
      ),
    );
  }
}
