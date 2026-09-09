import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Modal dialog rendered when `ExamAttemptBloc` reaches
/// `AttemptError(LockdownActivationException)` — the user-readable
/// equivalent of the in-memory failure list. Retry re-dispatches
/// [SessionResolutionRequested]; Cancel returns the user to the
/// session-entry screen.
///
/// Note: this widget is intentionally a `StatelessWidget` — the dialog
/// owns its own actions (the buttons live inside it, rather than as a
/// `showDialog` callback chain), which keeps the caller from having to
/// wire two callbacks across a transient route.
class LockdownActivationFailureDialog extends StatelessWidget {
  const LockdownActivationFailureDialog({
    required this.failedChecks,
    required this.onRetry,
    super.key,
  });

  final List<String> failedChecks;
  final VoidCallback onRetry;

  /// Convenience helper. Caller pattern:
  ///
  /// ```dart
  /// if (state.error is LockdownActivationException) {
  ///   LockdownActivationFailureDialog.show(
  ///     context,
  ///     failedChecks: (state.error as LockdownActivationException).failedChecks,
  ///     onRetry: () => bloc.add(SessionResolutionRequested(...)),
  ///   );
  /// }
  /// ```
  static Future<void> show(
    BuildContext context, {
    required List<String> failedChecks,
    required VoidCallback onRetry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LockdownActivationFailureDialog(
        failedChecks: failedChecks,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ExamAttemptStrings.lockdownFailureTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(ExamAttemptStrings.lockdownFailureMessage),
          const SizedBox(height: AppDimensions.spacingMedium),
          ...failedChecks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.examHeaderInstructionSpacing,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: AppDimensions.taskAdvanceWarningIconSize,
                  ),
                  const SizedBox(width: AppDimensions.dragChipSpacing),
                  Expanded(child: Text(check)),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ExamAttemptStrings.lockdownFailureCancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry();
          },
          child: const Text(ExamAttemptStrings.lockdownFailureRetry),
        ),
      ],
    );
  }
}
