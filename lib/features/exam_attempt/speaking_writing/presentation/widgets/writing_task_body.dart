import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/components/exam_textarea.dart';
import 'package:pte_app/core/widgets/templates/free_text_template.dart';
import 'package:pte_app/features/exam_attempt/domain/word_count.dart';
import 'text_editor_toolbar.dart';

/// Shared writing composition; callers provide task copy and persistence.
class WritingTaskBody extends StatefulWidget {
  const WritingTaskBody({
    super.key,
    required this.title,
    required this.section,
    required this.instruction,
    required this.prompt,
    required this.responseLabel,
    required this.minWords,
    required this.maxWords,
    this.initialAnswer,
    this.persistDraft,
    this.enabled = true,
  });

  final String title;
  final String section;
  final String instruction;
  final String prompt;
  final String responseLabel;
  final int minWords;
  final int maxWords;
  final String? initialAnswer;
  final ValueChanged<String>? persistDraft;
  final bool enabled;

  @override
  State<WritingTaskBody> createState() => _WritingTaskBodyState();
}

class _WritingTaskBodyState extends State<WritingTaskBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAnswer ?? '')
      ..addListener(_onDraftChanged);
  }

  void _onDraftChanged() => widget.persistDraft?.call(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FreeTextTemplate(
    title: widget.title,
    subtitle: widget.section,
    instruction: widget.instruction,
    stimulus: Text(widget.prompt, style: AppTypography.bodyPassage),
    response: WritingResponseEditor(
      controller: _controller,
      label: widget.responseLabel,
      minWords: widget.minWords,
      maxWords: widget.maxWords,
      enabled: widget.enabled,
    ),
  );
}

/// Controller-owned editor shared by writing tasks without owning drafts.
class WritingResponseEditor extends StatelessWidget {
  const WritingResponseEditor({
    super.key,
    required this.controller,
    required this.label,
    required this.minWords,
    required this.maxWords,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final int minWords;
  final int? maxWords;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (minWords > 0 || maxWords != null)
        Text(
          AppStrings.writingWordRequirement(minWords, maxWords),
          style: AppTypography.examAnswer,
        ),
      const SizedBox(height: AppDimensions.spacingSm),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.examBodyRadius),
        ),
        child: Column(
          children: [
            IgnorePointer(
              ignoring: !enabled,
              child: TextEditorToolbar(
                controller: controller,
                trailing: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final count = countWords(value.text);
                    final outOfRange =
                        count < minWords ||
                        (maxWords != null && count > maxWords!);
                    return Text(
                      AppStrings.writingWordCounter(count, maxWords),
                      key: const ValueKey('writingWordCounter'),
                      style: AppTypography.examAnswer.copyWith(
                        color: !enabled && outOfRange
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: AppDimensions.writingEditorHeight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: ExamTextarea(
                  controller: controller,
                  enabled: enabled,
                  minLines: null,
                  maxLines: null,
                  expands: true,
                  labelText: label,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
