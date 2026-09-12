import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/components/exam_textarea.dart';
import 'package:pte_app/core/widgets/templates/free_text_template.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';

/// Pure UI body for Summarize Written Text — header + passage + editor +
/// word-count footer. No `ExamScaffold` dependency so the Chrome dev
/// preview can render it without dragging in `package:sqlite3` through
/// `ExamAppBar` → `ExamAttemptBloc` → `AnswerOutboxDao` → drift. The
/// production screen [SummarizeWrittenTextScreen] wraps this in
/// `ExamScaffold`; the chrome dev preview mounts this directly.
class SummarizeWrittenTextBody extends StatefulWidget {
  const SummarizeWrittenTextBody({
    super.key,
    required this.task,
    this.persistDraft,
  });

  final TaskView task;
  final ValueChanged<String>? persistDraft;

  @override
  State<SummarizeWrittenTextBody> createState() =>
      _SummarizeWrittenTextBodyState();
}

class _SummarizeWrittenTextBodyState extends State<SummarizeWrittenTextBody> {
  late final TextEditingController _controller;
  int _wordCount = 0;
  final bool _timeExpired = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    final next = _countWords(_controller.text);
    widget.persistDraft?.call(_controller.text);
    if (next != _wordCount) setState(() => _wordCount = next);
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _passage => widget.task.promptText?.isNotEmpty == true
      ? widget.task.promptText!
      : kSummarizeWrittenTextPassage;

  int get _minWords =>
      widget.task.minWordCount ?? int.parse(kSummarizeWrittenTextMinWords);
  int get _maxWords =>
      widget.task.maxWordCount ?? int.parse(kSummarizeWrittenTextMaxWords);

  @override
  Widget build(BuildContext context) {
    return FreeTextTemplate(
      title: AppStrings.summarizeWrittenTextTitle,
      subtitle: widget.task.section,
      instruction: AppStrings.summarizeWrittenTextInstruction,
      metadata: ['$_minWords–$_maxWords words'],
      stimulus: Text(_passage, style: AppTypography.bodyPassage),
      response: Column(
        children: [
          _EditorBox(controller: _controller, timeExpired: _timeExpired),
          const SizedBox(height: AppDimensions.spacingMd),
          _WordCountFooter(
            count: _wordCount,
            min: _minWords,
            max: _maxWords,
            timeExpired: _timeExpired,
          ),
        ],
      ),
    );
  }
}

class _EditorBox extends StatelessWidget {
  const _EditorBox({required this.controller, required this.timeExpired});

  final TextEditingController controller;
  final bool timeExpired;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusDefault),
      ),
      child: Column(
        children: [
          TextEditorToolbar(controller: controller),
          SizedBox(
            height: 320,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              child: ExamTextarea(
                controller: controller,
                enabled: !timeExpired,
                minLines: null,
                maxLines: null,
                expands: true,
                labelText: AppStrings.summarizeWrittenTextResponseLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordCountFooter extends StatelessWidget {
  const _WordCountFooter({
    required this.count,
    required this.min,
    required this.max,
    required this.timeExpired,
  });

  final int count;
  final int min;
  final int max;
  final bool timeExpired;

  @override
  Widget build(BuildContext context) {
    final inRange = count >= min && count <= max;
    final color = timeExpired && !inRange
        ? AppColors.error
        : AppColors.textPrimary;
    return Text(
      _wordCountFooter(count: count, min: min, max: max),
      style: TextStyle(color: color),
    );
  }

  String _wordCountFooter({
    required int count,
    required int min,
    required int max,
  }) {
    return '$count${AppStrings.wordCountSuffix}'
        '${AppStrings.wordCountBoundsOpen}'
        '${AppStrings.wordCountMinLabel}$min'
        '${AppStrings.wordCountBoundsSeparator}'
        '${AppStrings.wordCountMaxLabel}$max'
        '${AppStrings.wordCountBoundsClose}';
  }
}
