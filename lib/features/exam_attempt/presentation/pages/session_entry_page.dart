import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/friendly_error_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../bloc/exam_attempt_state.dart';
import 'reading_instructions_screen.dart';

/// Placeholder manual session-ID entry screen — the only thing that
/// changes when Member 3's session-discovery decision lands is which
/// `SessionEntryRepository` is registered in DI; this widget only
/// dispatches [SessionResolutionRequested] and never itself decides how a
/// session ID is resolved (phase-03 Design Constraints).
///
/// Gated behind [ReadingInstructionsScreen] (Screen 1 of the Reading flow)
/// so the attempt — and its countdown — only starts once the student taps
/// past the instructions, not the moment this page is reached.
class SessionEntryPage extends StatefulWidget {
  const SessionEntryPage({super.key});

  @override
  State<SessionEntryPage> createState() => _SessionEntryPageState();
}

class _SessionEntryPageState extends State<SessionEntryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _showInstructions = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showInstructions) {
      return ReadingInstructionsScreen(onContinue: () => setState(() => _showInstructions = false));
    }
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessionEntryTitle)),
      body: BlocConsumer<ExamAttemptBloc, ExamAttemptState>(
        listener: (context, state) {
          if (state is AttemptError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(state.error))));
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
                  decoration: const InputDecoration(labelText: AppStrings.sessionEntryFieldLabel),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                PrimaryButton(
                  label: AppStrings.sessionEntryStartButton,
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
