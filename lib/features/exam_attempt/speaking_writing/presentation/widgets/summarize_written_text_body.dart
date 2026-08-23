import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/passage_panel.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/writing_task_header.dart';

/// Pure UI body for Summarize Written Text — header + passage + editor +
/// word-count footer. No `ExamScaffold` dependency so the Chrome dev
/// preview can render it without dragging in `package:sqlite3` through
/// `ExamAppBar` → `ExamAttemptBloc` → `AnswerOutboxDao` → drift. The
/// production screen [SummarizeWrittenTextScreen] wraps this in
/// `ExamScaffold`; the chrome dev preview mounts this directly.
class SummarizeWrittenTextBody extends StatefulWidget {
  const SummarizeWrittenTextBody({super.key, required this.task});

  final TaskView task;

  @override
  State<SummarizeWrittenTextBody> createState() => _SummarizeWrittenTextBodyState();
}

class _SummarizeWrittenTextBodyState extends State<SummarizeWrittenTextBody> {
  late final TextEditingController _controller;
  int _wordCount = 0;
  bool _timeExpired = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    final next = _countWords(_controller.text);
    if (next != _wordCount) setState(() => _wordCount = next);
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  void _handleTimeExpired() {
    if (!mounted) return;
    setState(() => _timeExpired = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _passage => widget.task.promptText?.isNotEmpty == true
      ? widget.task.promptText!
      : kSummarizeWrittenTextPassage;

  int get _minWords => widget.task.minWordCount ?? int.parse(kSummarizeWrittenTextMinWords);
  int get _maxWords => widget.task.maxWordCount ?? int.parse(kSummarizeWrittenTextMaxWords);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WritingTaskHeader(
            title: AppStrings.summarizeWrittenTextTitle,
            instruction: AppStrings.summarizeWrittenTextInstruction,
            totalSeconds: kSummarizeWrittenTextDurationSeconds,
            onTimeExpired: _handleTimeExpired,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          PassagePanel(body: _passage),
          const SizedBox(height: AppDimensions.spacingMedium),
          Expanded(child: _EditorBox(controller: _controller, timeExpired: _timeExpired)),
          const SizedBox(height: AppDimensions.spacingMedium),
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
        border: Border.all(color: AppColors.passagePanelBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          TextEditorToolbar(controller: controller),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMedium),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                enabled: !timeExpired,
                decoration: const InputDecoration(
                  labelText: AppStrings.summarizeWrittenTextResponseLabel,
                  border: InputBorder.none,
                ),
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
    final color = timeExpired && !inRange ? AppColors.error : AppColors.textPrimary;
    return Text(
      _wordCountFooter(count: count, min: min, max: max),
      style: TextStyle(color: color),
    );
  }

  String _wordCountFooter({required int count, required int min, required int max}) {
    return '$count${AppStrings.wordCountSuffix}'
        '${AppStrings.wordCountBoundsOpen}'
        '${AppStrings.wordCountMinLabel}$min'
        '${AppStrings.wordCountBoundsSeparator}'
        '${AppStrings.wordCountMaxLabel}$max'
        '${AppStrings.wordCountBoundsClose}';
  }
}
