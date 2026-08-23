import 'package:flutter/material.dart';

import '../../domain/task_view.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/summarize_written_text_body.dart';

/// Production wrapper for Summarize Written Text — composes the pure UI
/// body inside the existing `ExamScaffold` frame so the dispatcher-driven
/// task bar (phase/totalTasks/force-submit) is preserved alongside the
/// new writing-task header.
class SummarizeWrittenTextScreen extends StatelessWidget {
  const SummarizeWrittenTextScreen({super.key, required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      totalTasks: task.totalTasks,
      body: SummarizeWrittenTextBody(task: task),
    );
  }
}
