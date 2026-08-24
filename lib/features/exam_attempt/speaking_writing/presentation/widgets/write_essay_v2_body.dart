import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/passage_panel.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/writing_task_header.dart';

/// Pure UI body for the Write Essay v2 task — header + prompt + editor +
/// word-count footer. No `ExamScaffold` import so the Chrome dev preview
/// can render this without compiling `package:sqlite3` (which transitively
/// follows from `ExamAppBar` → `ExamAttemptBloc` → `AnswerOutboxDao`).
/// The production screen [WriteEssayV2Screen] wraps this in
/// `ExamScaffold`; the chrome dev preview mounts this directly.
class WriteEssayV2Body extends StatefulWidget {
  const WriteEssayV2Body({super.key, required this.task});

  final TaskView task;

  @override
  State<WriteEssayV2Body> createState() => _WriteEssayV2BodyState();
}

class _WriteEssayV2BodyState extends State<WriteEssayV2Body> {
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

  void _handleTimeExpired() {
    if (!mounted) return;
    setState(() => _timeExpired = true);
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

  String get _prompt => widget.task.promptText?.isNotEmpty == true
      ? widget.task.promptText!
      : kWriteEssayPrompt;

  int get _minWords => widget.task.minWordCount ?? int.parse(kWriteEssayMinWords);
  int get _maxWords => widget.task.maxWordCount ?? int.parse(kWriteEssayMaxWords);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WritingTaskHeader(
            title: AppStrings.writeEssayV2Title,
            instruction: AppStrings.writeEssayV2Instruction,
            totalSeconds: kWriteEssayDurationSeconds,
            onTimeExpired: _handleTimeExpired,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          PassagePanel(body: _prompt),
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
                  labelText: AppStrings.writeEssayV2ResponseLabel,
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
