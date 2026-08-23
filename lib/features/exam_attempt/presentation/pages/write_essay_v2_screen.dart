import 'package:flutter/material.dart';

import '../../domain/task_view.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/write_essay_v2_body.dart';

/// Production wrapper for the Write Essay v2 task — composes the pure UI
/// body inside the existing `ExamScaffold` so the dispatcher-driven task
/// bar (phase/totalTasks/force-submit) is preserved alongside the new
/// writing-task header.
class WriteEssayV2Screen extends StatelessWidget {
  const WriteEssayV2Screen({super.key, required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      totalTasks: task.totalTasks,
      body: WriteEssayV2Body(task: task),
    );
  }
}
