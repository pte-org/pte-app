import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_app_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_bottom_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/violation_warning_banner.dart';

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
    // The violation banner listens to `LockdownService.violations` —
    // a broadcast stream that lives across the whole app, so the
    // banner simply renders nothing on its own when no violation is
    // observed. Hoisting the stream source here (rather than inside
    // the banner widget) keeps it possible to test the banner in
    // isolation by passing a synthetic `StreamController`.
    //
    // LockdownService is a GetIt singleton service, not a Bloc/Cubit —
    // this app never wires a widget-tree `Provider<LockdownService>`
    // (it only uses flutter_bloc's BlocProvider for Blocs/Cubits, e.g.
    // ExamAttemptBloc gets LockdownService via constructor injection
    // from GetIt). `context.read<LockdownService>()` here had no
    // ancestor provider anywhere and threw ProviderNotFoundError.
    final lockdownStream = GetIt.instance<LockdownService>().violations;
    return Scaffold(
      body: Column(
        children: [
          ViolationWarningBanner(violations: lockdownStream),
          ExamAppBar(totalTasks: widget.totalTasks),
          Expanded(child: widget.body),
          ExamBottomBar(action: widget.bottomAction),
        ],
      ),
    );
  }
}
