import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_app_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_bottom_bar.dart';

/// Composes [ExamAppBar] + task-type-specific content (injected by Phase
/// 5/6) + [ExamBottomBar]. No internal `Timer.periodic` of its own — the
/// countdown display is driven exclusively by `TimerService.ticks` via the
/// bar widgets' own `BlocSelector`s (phase-04 Design Constraints).
///
/// The single wrapper for every task screen, so it's also the natural place
/// to observe app-lifecycle transitions: on resume, it dispatches
/// [AppResumed] to force an immediate timer re-poll rather than waiting up
/// to the normal poll interval, since the OS may have suspended the app
/// (and its local countdown display) for an unknown stretch while
/// backgrounded.
class ExamScaffold extends StatefulWidget {
  const ExamScaffold({super.key, required this.totalTasks, required this.body, this.bottomAction});

  final int totalTasks;
  final Widget body;
  final Widget? bottomAction;

  @override
  State<ExamScaffold> createState() => _ExamScaffoldState();
}

class _ExamScaffoldState extends State<ExamScaffold> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ExamAttemptBloc>().add(const AppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ExamAppBar(totalTasks: widget.totalTasks),
          Expanded(child: widget.body),
          ExamBottomBar(action: widget.bottomAction),
        ],
      ),
    );
  }
}
