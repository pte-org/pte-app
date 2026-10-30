import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';
import 'writing_task_body.dart';

class WriteEssayV2Body extends StatelessWidget {
  const WriteEssayV2Body({
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
    title: AppStrings.writeEssayV2Title,
    section: task.section,
    instruction: AppStrings.writeEssayV2Instruction,
    prompt: task.promptText?.isNotEmpty == true
        ? task.promptText!
        : kWriteEssayPrompt,
    responseLabel: AppStrings.writeEssayV2ResponseLabel,
    minWords: task.minWordCount ?? int.parse(kWriteEssayMinWords),
    maxWords: task.maxWordCount ?? int.parse(kWriteEssayMaxWords),
    initialAnswer: initialAnswer,
    persistDraft: persistDraft,
  );
}
