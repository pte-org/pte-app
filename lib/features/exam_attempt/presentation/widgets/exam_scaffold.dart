import 'package:flutter/material.dart';

import 'exam_app_bar.dart';
import 'exam_bottom_bar.dart';

/// Composes [ExamAppBar] + task-type-specific content (injected by Phase
/// 5/6) + [ExamBottomBar]. No internal `Timer.periodic` of its own — the
/// countdown display is driven exclusively by `TimerService.ticks` via the
/// bar widgets' own `BlocSelector`s (phase-04 Design Constraints).
class ExamScaffold extends StatelessWidget {
  const ExamScaffold({super.key, required this.totalTasks, required this.body, this.bottomAction});

  final int totalTasks;
  final Widget body;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ExamAppBar(totalTasks: totalTasks),
          Expanded(child: body),
          ExamBottomBar(action: bottomAction),
        ],
      ),
    );
  }
}
