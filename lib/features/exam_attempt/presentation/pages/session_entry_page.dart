import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../bloc/exam_attempt_state.dart';

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
      appBar: AppBar(title: const Text(AppStrings.sessionEntryTitle)),
      body: BlocConsumer<ExamAttemptBloc, ExamAttemptState>(
        listener: (context, state) {
          if (state is AttemptError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error.toString())));
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
                ElevatedButton(
                  onPressed: state is AttemptStarting
                      ? null
                      : () => context.read<ExamAttemptBloc>().add(const SessionResolutionRequested()),
                  child: state is AttemptStarting
                      ? const CircularProgressIndicator()
                      : const Text(AppStrings.sessionEntryStartButton),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
