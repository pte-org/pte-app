import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'package:pte_app/core/widgets/templates/task_template_body.dart';
import 'package:pte_app/core/widgets/templates/exam_task_frame.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'host_preview_fill_blanks_response.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/reading_choice_task_frame.dart';

import '../model/preview_task_ui_model.dart';
import 'preview_media_status.dart';
import 'host_preview_stimulus.dart';
import 'host_preview_response.dart';
import 'host_preview_audio_prompt_panel.dart';
import '../../data/preview_audio_session.dart';
import 'package:pte_app/core/widgets/templates/status_speaking_task_frame.dart';

class HostPreviewTaskDispatcher extends StatelessWidget {
  const HostPreviewTaskDispatcher({
    super.key,
    required this.model,
    required this.answer,
    required this.onAnswerChanged,
    this.onAudioPressed,
    this.remainingSeconds,
    this.isPreparing = false,
    this.recordingUnavailable = false,
    this.inputLevels,
    this.audioPosition,
    this.isRecording = false,
    this.isRecordingPaused = false,
    this.mediaSession,
    this.onRecordingPauseResume,
    this.onRecordingStop,
  });

  final PreviewTaskUiModel model;
  final Object? answer;
  final ValueChanged<Object?> onAnswerChanged;
  final VoidCallback? onAudioPressed;
  final int? remainingSeconds;
  final bool isPreparing;
  final bool recordingUnavailable;
  final Stream<double>? inputLevels;
  final Stream<Duration>? audioPosition;
  final bool isRecording;
  final bool isRecordingPaused;
  final PreviewAudioSession? mediaSession;
  final VoidCallback? onRecordingPauseResume;
  final VoidCallback? onRecordingStop;

  @override
  Widget build(BuildContext context) {
    if (!model.isSupported) {
      return PreviewMediaStatus(
        title: ExamPreviewStrings.unsupportedTitle,
        message: ExamPreviewStrings.unsupportedTask(
          model.resolution.identifier,
        ),
        isError: true,
      );
    }
    final combinedAudioPrompt = _isCombinedAudioPrompt(model);
    final canonical = TaskTypeCodes.canonicalize(model.taskType);
    if (canonical == TaskTypeCodes.fillInTheBlanksTypeIn ||
        canonical == TaskTypeCodes.highlightIncorrectWords) {
      return ExamTaskFrame(
        title: model.meta!.title,
        instruction: model.instruction,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HostPreviewStimulus(
              model: model,
              onlyAudio: true,
              mediaSession: mediaSession,
              audioPosition: audioPosition,
              onAudioPressed: onAudioPressed,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            if (canonical == TaskTypeCodes.fillInTheBlanksTypeIn)
              HostPreviewFillBlanksResponse(
                key: ValueKey(model.item.snapshotItemPublicId),
                model: model,
                answer: answer,
                onChanged: onAnswerChanged,
              ),
            if (canonical == TaskTypeCodes.highlightIncorrectWords)
              HostPreviewResponse(
                key: ValueKey(model.item.snapshotItemPublicId),
                model: model,
                answer: answer,
                onAnswerChanged: onAnswerChanged,
              ),
          ],
        ),
      );
    }
    if (canonical == TaskTypeCodes.mcReadingSingle ||
        canonical == TaskTypeCodes.mcReadingMultiple) {
      return ReadingChoiceTaskFrame(
        title: model.meta!.title,
        instruction: model.instruction,
        promptText: model.item.promptText,
        response: HostPreviewResponse(
          key: ValueKey(model.item.snapshotItemPublicId),
          model: model,
          answer: answer,
          onAnswerChanged: onAnswerChanged,
        ),
      );
    }
    if (canonical == TaskTypeCodes.reOrderParagraphs) {
      return ExamTaskFrame(
        title: model.meta!.title,
        instruction: model.instruction,
        body: HostPreviewResponse(
          key: ValueKey(model.item.snapshotItemPublicId),
          model: model,
          answer: answer,
          onAnswerChanged: onAnswerChanged,
        ),
      );
    }
    if (canonical == TaskTypeCodes.fillInTheBlanksDropdown ||
        canonical == TaskTypeCodes.fillInTheBlanksDragAndDrop) {
      return ExamTaskFrame(
        title: model.meta!.title,
        instruction: model.instruction,
        maxWidth: AppDimensions.readingWorkstationMaxWidth,
        body: HostPreviewFillBlanksResponse(
          key: ValueKey(model.item.snapshotItemPublicId),
          model: model,
          answer: answer,
          onChanged: onAnswerChanged,
        ),
      );
    }
    if (usesStatusAudioPanels(model.taskType)) {
      return StatusSpeakingTaskFrame(
        taskType: model.taskType,
        title: model.meta!.title,
        instruction: model.instruction,
        promptText: model.item.promptText,
        image: model.item.imageUrl == null
            ? null
            : HostPreviewStimulus(model: model, imageOnly: true),
        panels: HostPreviewAudioPromptPanel(
          key: ValueKey(model.item.snapshotItemPublicId),
          model: model,
          mediaSession: mediaSession,
          remainingSeconds: remainingSeconds,
          isPreparing: isPreparing,
          recordingUnavailable: recordingUnavailable,
          inputLevels: inputLevels,
          audioPosition: audioPosition,
          isRecording: isRecording,
          isRecordingPaused: isRecordingPaused,
          onRecordingPauseResume: onRecordingPauseResume,
          onRecordingStop: onRecordingStop,
        ),
      );
    }
    return TaskTemplateBody(
      taskType: model.taskType,
      family: model.meta!.family,
      title: model.title,
      section: model.item.section,
      instruction: model.instruction,
      stimulus: model.stimulus,
      metadata: _metadata(model),
      hasSupplementaryContentOverride: combinedAudioPrompt
          ? model.stimulus.parts.any(
              (part) =>
                  part.kind != StimulusPartKind.image &&
                  part.kind != StimulusPartKind.audio,
            )
          : null,
      stimulusBuilder: (imageOnly) => HostPreviewStimulus(
        model: model,
        imageOnly: imageOnly,
        excludeAudio: combinedAudioPrompt,
        showEmptyState: !combinedAudioPrompt,
        onAudioPressed: onAudioPressed,
        audioPosition: audioPosition,
        mediaSession: mediaSession,
      ),
      response: combinedAudioPrompt
          ? HostPreviewAudioPromptPanel(
              key: ValueKey(model.item.snapshotItemPublicId),
              model: model,
              mediaSession: mediaSession,
              onAudioPressed: onAudioPressed,
              remainingSeconds: remainingSeconds,
              isPreparing: isPreparing,
              recordingUnavailable: recordingUnavailable,
              inputLevels: inputLevels,
              audioPosition: audioPosition,
              isRecording: isRecording,
              isRecordingPaused: isRecordingPaused,
              onRecordingPauseResume: onRecordingPauseResume,
              onRecordingStop: onRecordingStop,
            )
          : HostPreviewResponse(
              key: ValueKey(model.item.snapshotItemPublicId),
              model: model,
              answer: answer,
              onAnswerChanged: onAnswerChanged,
              remainingSeconds: remainingSeconds,
              isPreparing: isPreparing,
              recordingUnavailable: recordingUnavailable,
              inputLevels: inputLevels,
              isRecording: isRecording,
              isRecordingPaused: isRecordingPaused,
              onPauseResume: onRecordingPauseResume,
              onStop: onRecordingStop,
            ),
    );
  }

  bool _isCombinedAudioPrompt(PreviewTaskUiModel model) {
    return model.meta!.family == TaskTemplateFamily.recordResponse &&
        model.stimulus.parts.any((part) => part.kind == StimulusPartKind.audio);
  }

  List<String> _metadata(PreviewTaskUiModel model) {
    final values = <String>[];
    if (model.item.prepSeconds > 0 || model.item.responseSeconds > 0) {
      values.add(
        ExamPreviewStrings.taskTiming(
          model.item.prepSeconds,
          model.item.responseSeconds,
        ),
      );
    }
    final min = model.item.minWordCount;
    final max = model.item.maxWordCount;
    if (min != null || max != null) {
      values.add(ExamPreviewStrings.wordBounds(min, max));
    }
    values.add(ExamPreviewStrings.previewOnly);
    return values;
  }
}
