import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/sync/submission_preparation_exception.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_error_message.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_app_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_bottom_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';
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
    final syncEngine = GetIt.instance.isRegistered<SyncEngine>()
        ? GetIt.instance<SyncEngine>()
        : null;
    final outboxDao = GetIt.instance.isRegistered<AnswerOutboxDao>()
        ? GetIt.instance<AnswerOutboxDao>()
        : null;
    final navigationAction =
        widget.bottomAction ??
        (syncEngine == null
            ? null
            : TaskAdvanceButton(
                syncEngine: syncEngine,
                autoAdvanceOnExpiration: false,
              ));
    // Native close/focus/minimize attempts are handled by the Windows runner;
    // this PopScope covers Flutter-owned route/back dispatches so no second
    // exit path can bypass the same server-acknowledgement gate.
    return PopScope(
      canPop: false,
      child: ExamShell(
        topNotice: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ViolationWarningBanner(violations: lockdownStream),
            const _SubmissionStatusNotice(),
          ],
        ),
        header: ExamAppBar(totalTasks: widget.totalTasks, outboxDao: outboxDao),
        body: _SubmissionInteractionGuard(child: widget.body),
        footer: ExamBottomBar(action: navigationAction),
      ),
    );
  }
}

/// Prevents edits and navigation while the terminal submit request is in
/// flight. The BLoC remains the authority; this is only the shared visual
/// interaction guard so every task type behaves consistently.
class _SubmissionInteractionGuard extends StatelessWidget {
  const _SubmissionInteractionGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
      buildWhen: (previous, current) =>
          previous is AttemptInProgress && current is AttemptInProgress
          ? previous.submissionStatus != current.submissionStatus
          : previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        final submitting =
            state is AttemptInProgress &&
            state.submissionStatus == AttemptSubmissionStatus.submitting;
        if (!submitting) return child;
        return Stack(
          children: [
            IgnorePointer(child: child),
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.surfaceCanvas.withValues(alpha: 0.72),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacingMd),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppDimensions.spacingSm),
                          Text(ExamAttemptStrings.forceSubmitInProgress),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SubmissionStatusNotice extends StatelessWidget {
  const _SubmissionStatusNotice();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
      buildWhen: (previous, current) {
        final previousStatus = previous is AttemptInProgress
            ? previous.submissionStatus
            : null;
        final currentStatus = current is AttemptInProgress
            ? current.submissionStatus
            : null;
        return previousStatus != currentStatus;
      },
      builder: (context, state) {
        if (state is! AttemptInProgress ||
            state.submissionStatus !=
                AttemptSubmissionStatus.retryableFailure) {
          return const SizedBox.shrink();
        }
        return Material(
          color: AppColors.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.errorDark),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      state.submissionError is SubmissionPreparationException
                          ? examAttemptFriendlyErrorMessage(
                              state.submissionError!,
                            )
                          : ExamAttemptStrings.forceSubmitRetryMessage,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<ExamAttemptBloc>().add(
                      const ForceSubmitRequested(),
                    ),
                    child: const Text(ExamAttemptStrings.forceSubmitRetryLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
