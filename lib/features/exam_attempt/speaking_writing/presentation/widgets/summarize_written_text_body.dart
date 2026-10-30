import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';
import 'writing_task_body.dart';

class SummarizeWrittenTextBody extends StatelessWidget {
  const SummarizeWrittenTextBody({
    super.key,
    required this.task,
    this.initialAnswer,
    this.persistDraft,
  });

  final TaskView task;
  final String? initialAnswer;
  final ValueChanged<String>? persistDraft;

  @override
  Widget build(BuildContext context) => WritingTaskBody(
    title: AppStrings.summarizeWrittenTextTitle,
    section: task.section,
    instruction: AppStrings.summarizeWrittenTextInstruction,
    prompt: task.promptText?.isNotEmpty == true
        ? task.promptText!
        : kSummarizeWrittenTextPassage,
    responseLabel: AppStrings.summarizeWrittenTextResponseLabel,
    minWords: task.minWordCount ?? int.parse(kSummarizeWrittenTextMinWords),
    maxWords: task.maxWordCount ?? int.parse(kSummarizeWrittenTextMaxWords),
    initialAnswer: initialAnswer,
    persistDraft: persistDraft,
  );
}
