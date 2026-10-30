import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_strings.dart';

import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/components/choice_list.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';

import 'package:pte_app/features/exam_attempt/listening/domain/transcript_words.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/word_selection_list.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recorded_answer_status_card.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/writing_task_body.dart';
import 'preview_media_status.dart';
import 'host_preview_ordering_response.dart';
import 'host_preview_fill_blanks_response.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';

class HostPreviewResponse extends StatefulWidget {
  const HostPreviewResponse({
    super.key,
    required this.model,
    required this.answer,
    required this.onAnswerChanged,
    this.remainingSeconds,
    this.isPreparing = false,
    this.recordingUnavailable = false,
    this.inputLevels,
    this.isRecording = false,
    this.isRecordingPaused = false,
    this.onPauseResume,
    this.onStop,
  });

  final PreviewTaskUiModel model;
  final Object? answer;
  final ValueChanged<Object?> onAnswerChanged;
  final int? remainingSeconds;
  final bool isPreparing;
  final bool recordingUnavailable;
  final Stream<double>? inputLevels;
  final bool isRecording;
  final bool isRecordingPaused;
  final VoidCallback? onPauseResume;
  final VoidCallback? onStop;

  @override
  State<HostPreviewResponse> createState() => HostPreviewResponseState();
}

class HostPreviewResponseState extends State<HostPreviewResponse> {
  late final TextEditingController _textController;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _lastText = _textAnswer;
    _textController = TextEditingController(text: _textAnswer)
      ..addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_lastText == _textController.text) return;
    _lastText = _textController.text;
    widget.onAnswerChanged(_lastText);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant HostPreviewResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.item.snapshotItemPublicId !=
        widget.model.item.snapshotItemPublicId) {
      _textController.text = _textAnswer;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _textAnswer =>
      widget.answer is String ? widget.answer as String : '';

  @override
  Widget build(BuildContext context) {
    final family = widget.model.meta!.family;
    if (family == TaskTemplateFamily.recordResponse) {
      final seconds = widget.remainingSeconds ?? widget.model.item.prepSeconds;
      final total = widget.isPreparing
          ? widget.model.item.prepSeconds
          : widget.model.item.responseSeconds;
      final label = widget.recordingUnavailable
          ? SpeakingWritingStrings.recordingMicrophoneUnavailableLabel
          : widget.isRecordingPaused
          ? ExamPreviewStrings.paused
          : widget.isPreparing
          ? '${SpeakingWritingStrings.recordingBeginningInPrefix}$seconds${SpeakingWritingStrings.recordingBeginningInSuffix}'
          : seconds == 0 && !widget.isRecording
          ? ExamPreviewStrings.completed
          : '${SpeakingWritingStrings.recordingInProgressPrefix}$seconds${SpeakingWritingStrings.recordingInProgressSuffix}';
      return RecordedAnswerStatusCard(
        isPreparing:
            widget.isPreparing &&
            !widget.recordingUnavailable &&
            !widget.isRecording,
        statusLabel: label,
        progress: widget.isPreparing || total <= 0
            ? 0
            : ((total - seconds) / total).clamp(0.0, 1.0),
        inputLevels: widget.isRecording && !widget.isRecordingPaused
            ? widget.inputLevels
            : null,
        playing: widget.isRecording && !widget.isRecordingPaused,
        onPauseResume: widget.isRecording ? widget.onPauseResume : null,
        onStop: widget.isRecording ? widget.onStop : null,
        timeLabel:
            '${formatPteAudioDuration(Duration(seconds: widget.isPreparing ? 0 : (total - seconds).clamp(0, total > 0 ? total : 0)))}${AppStrings.audioTimeSeparator}${formatPteAudioDuration(Duration(seconds: widget.model.item.responseSeconds))}',
      );
    }
    if (family == TaskTemplateFamily.freeText) {
      return WritingResponseEditor(
        controller: _textController,
        label: AppStrings.writeEssayTextFieldLabel,
        minWords: widget.model.item.minWordCount ?? 0,
        maxWords: widget.model.item.maxWordCount,
      );
    }
    if (family == TaskTemplateFamily.singleSelect ||
        family == TaskTemplateFamily.multiSelect) {
      final selected = _asIntSet(widget.answer);
      return ChoiceList(
        plain:
            widget.model.item.section == 'READING' ||
            TaskTypeCodes.canonicalize(widget.model.taskType) ==
                TaskTypeCodes.mcListeningMultiple,
        labels: [for (final option in widget.model.item.options) option.text],
        selectedIndices: selected,
        mode: family == TaskTemplateFamily.multiSelect
            ? ChoiceSelectionMode.multiple
            : ChoiceSelectionMode.single,
        onTap: (index) {
          if (family == TaskTemplateFamily.singleSelect) {
            widget.onAnswerChanged(<int>[index]);
          } else {
            final next = {...selected};
            if (!next.add(index)) next.remove(index);
            widget.onAnswerChanged(next.toList()..sort());
          }
        },
      );
    }
    if (family == TaskTemplateFamily.tokenToggle) {
      final selected = _asIntSet(widget.answer);
      return WordSelectionList(
        words: splitTranscriptWords(widget.model.item.promptText ?? ''),
        transcript: widget.model.item.promptText,
        selectedIndices: selected,
        onToggle: (index) {
          final next = {...selected};
          if (!next.add(index)) next.remove(index);
          widget.onAnswerChanged(next.toList()..sort());
        },
      );
    }
    if (family == TaskTemplateFamily.ordering) {
      return HostPreviewOrderingResponse(
        model: widget.model,
        answer: widget.answer,
        onChanged: widget.onAnswerChanged,
      );
    }
    if (family == TaskTemplateFamily.fillBlanks) {
      return HostPreviewFillBlanksResponse(
        model: widget.model,
        answer: widget.answer,
        onChanged: widget.onAnswerChanged,
      );
    }
    return const PreviewMediaStatus(
      title: ExamPreviewStrings.responseErrorTitle,
      message: ExamPreviewStrings.responseErrorMessage,
      isError: true,
    );
  }

  Set<int> _asIntSet(Object? value) => value is Iterable
      ? value.whereType<num>().map((number) => number.toInt()).toSet()
      : <int>{};
}
