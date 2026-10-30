import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/core/widgets/loading_view.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/core/widgets/status_screen.dart';

import '../../constants/exam_preview_strings.dart';
import '../../data/preview_audio_session.dart';
import '../../domain/repositories/host_exam_preview_repository.dart';
import '../cubit/host_exam_preview_cubit.dart';
import '../cubit/host_exam_preview_state.dart';
import '../model/preview_task_ui_adapter.dart';
import '../widgets/host_preview_navigation.dart';
import '../widgets/host_preview_task_dispatcher.dart';

/// Host execution uses the candidate shell and shared task UI, backed only by
/// a read-only snapshot and in-memory answers rather than a student attempt.
class HostExamPreviewScreen extends StatelessWidget {
  const HostExamPreviewScreen({
    super.key,
    required this.sessionInput,
    required this.repository,
    this.mediaSession,
    this.onExit,
  });

  final String sessionInput;
  final HostExamPreviewRepository repository;
  final PreviewAudioSession? mediaSession;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        HostExamPreviewCubit(repository: repository, mediaSession: mediaSession)
          ..loadForEntry(sessionInput),
    child: _HostExamView(sessionInput: sessionInput, onExit: onExit),
  );
}

class _HostExamView extends StatelessWidget {
  const _HostExamView({required this.sessionInput, this.onExit});

  final String sessionInput;
  final VoidCallback? onExit;

  void _exit(BuildContext context) {
    if (onExit != null) {
      onExit!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<HostExamPreviewCubit, HostExamPreviewState>(
        listenWhen: (_, current) => current is HostExamPreviewFinished,
        listener: (context, _) => _exit(context),
        builder: (context, state) => switch (state) {
          HostExamPreviewInitial() ||
          HostExamPreviewLoading() => const Scaffold(body: LoadingView()),
          HostExamPreviewError(:final error) => StatusScreen(
            icon: Icons.error_outline,
            title: ExamPreviewStrings.previewErrorTitle,
            message: error is FormatException
                ? error.message
                : ExamPreviewStrings.previewErrorMessage,
            isError: true,
            children: [
              PrimaryButton(
                label: ExamPreviewStrings.retry,
                onPressed: () => context
                    .read<HostExamPreviewCubit>()
                    .loadForEntry(sessionInput),
              ),
              TextButton(
                onPressed: () => _exit(context),
                child: const Text(AppStrings.logout),
              ),
            ],
          ),
          HostExamPreviewFinished() => const SizedBox.shrink(),
          HostExamPreviewReady() => _buildExam(context, state),
        },
      );

  Widget _buildExam(BuildContext context, HostExamPreviewReady state) {
    final cubit = context.read<HostExamPreviewCubit>();
    final item = state.currentItem;
    final remaining = state.remainingSeconds;
    return ExamShell(
      header: ExamHeaderBar(
        examTitle: state.snapshot.name,
        candidateName: ExamPreviewStrings.hostName,
        candidateId: sessionInput.trim(),
        itemLabel: ExamChromeConfig.itemLabel(
          orderIndex: state.currentIndex,
          totalTasks: state.snapshot.items.length,
        ),
        timeLabel: ExamChromeConfig.formatDuration(
          remaining == null ? null : Duration(seconds: remaining),
        ),
        onForceSubmit: state.isTransitioning ? null : cubit.finish,
      ),
      body: HostPreviewTaskDispatcher(
        key: ValueKey(item.snapshotItemPublicId),
        model: PreviewTaskUiAdapter.adapt(item),
        answer: cubit.answerFor(item),
        onAnswerChanged: cubit.setAnswer,
        onAudioPressed: item.audioUrl == null
            ? null
            : () => cubit.playAudio(item.audioUrl!),
        remainingSeconds: state.remainingSeconds,
        isPreparing: state.isPreparing,
        recordingUnavailable: state.recordingUnavailable,
        inputLevels: cubit.inputLevels,
        audioPosition: cubit.audioPosition,
        isRecording: state.isRecording,
        isRecordingPaused: state.isRecordingPaused,
        mediaSession: cubit.mediaSession,
        onRecordingPauseResume: cubit.mediaSession?.canPauseRecording == true
            ? cubit.toggleRecordingPause
            : null,
        onRecordingStop: cubit.stopRecording,
      ),
      footer: HostPreviewNavigation(
        isBusy: state.isTransitioning,
        onPrevious: cubit.previous,
        onNext: cubit.next,
      ),
    );
  }
}
