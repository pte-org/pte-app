import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_app_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_bottom_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/violation_warning_banner.dart';

/// Feature composition root for the props-only [ExamShell]. It is also the
/// lifecycle boundary that forwards app resume to the existing attempt BLoC.
class ExamScaffold extends StatefulWidget {
  const ExamScaffold({
    super.key,
    required this.totalTasks,
    required this.body,
    this.bottomAction,
  });

  final int totalTasks;
  final Widget body;
  final Widget? bottomAction;

  @override
  State<ExamScaffold> createState() => _ExamScaffoldState();
}

class _ExamScaffoldState extends State<ExamScaffold>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ExamAttemptBloc>().add(const AppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockdownStream = GetIt.instance.isRegistered<LockdownService>()
        ? GetIt.instance<LockdownService>().violations
        : const Stream<ViolationType>.empty();
    return ExamShell(
      topNotice: ViolationWarningBanner(violations: lockdownStream),
      header: ExamAppBar(totalTasks: widget.totalTasks),
      body: widget.body,
      footer: ExamBottomBar(action: widget.bottomAction),
    );
  }
}
