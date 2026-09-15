import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/network/friendly_error_message.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/lockdown_activation_failure_dialog.dart';

/// Placeholder manual session-ID entry screen — the only thing that
/// changes when Member 3's session-discovery decision lands is which
/// `SessionEntryRepository` is registered in DI; this widget only
/// dispatches [SessionResolutionRequested] and never itself decides how a
/// session ID is resolved (phase-03 Design Constraints).
class SessionEntryPage extends StatefulWidget {
  const SessionEntryPage({super.key});

  @override
  State<SessionEntryPage> createState() => _SessionEntryPageState();
}

class _SessionEntryPageState extends State<SessionEntryPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ExamAttemptStrings.sessionEntryTitle)),
      body: BlocConsumer<ExamAttemptBloc, ExamAttemptState>(
        listener: (context, state) {
          if (state is AttemptError) {
            final error = state.error;
            if (error is LockdownActivationException) {
              LockdownActivationFailureDialog.show(
                context,
                failedChecks: error.failedChecks,
                onRetry: () => context.read<ExamAttemptBloc>().add(
                      SessionResolutionRequested(rawInput: _controller.text),
                    ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(friendlyErrorMessage(state.error))),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: ExamAttemptStrings.sessionEntryFieldLabel),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                PrimaryButton(
                  label: ExamAttemptStrings.sessionEntryStartButton,
                  isLoading: state is AttemptStarting,
                  onPressed: () => context
                      .read<ExamAttemptBloc>()
                      .add(SessionResolutionRequested(rawInput: _controller.text)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
