import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/loading_view.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/core/widgets/status_screen.dart';

import '../../data/preview_audio_session.dart';
import '../../domain/repositories/host_exam_preview_repository.dart';
import '../cubit/host_exam_preview_cubit.dart';
import '../cubit/host_exam_preview_state.dart';
import '../model/preview_task_ui_adapter.dart';
import '../widgets/host_preview_navigation.dart';
import '../widgets/host_preview_task_dispatcher.dart';

class HostExamPreviewScreen extends StatelessWidget {
  const HostExamPreviewScreen({
    super.key,
    required this.sessionPublicId,
    required this.repository,
    this.mediaSession,
  });

  final String sessionPublicId;
  final HostExamPreviewRepository repository;
  final PreviewAudioSession? mediaSession;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HostExamPreviewCubit(
        repository: repository,
        mediaSession: mediaSession,
      )..load(sessionPublicId),
      child: _HostExamPreviewView(sessionPublicId: sessionPublicId),
    );
  }
}

class _HostExamPreviewView extends StatelessWidget {
  const _HostExamPreviewView({required this.sessionPublicId});

  final String sessionPublicId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<HostExamPreviewCubit, HostExamPreviewState>(
      listenWhen: (_, state) => state is HostExamPreviewFinished,
      listener: (context, _) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceCanvas,
        appBar: AppBar(
          title: const Text(ExamPreviewStrings.previewTitle),
          leading: BackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: BlocBuilder<HostExamPreviewCubit, HostExamPreviewState>(
          builder: (context, state) {
            return switch (state) {
              HostExamPreviewInitial() ||
              HostExamPreviewLoading() => const LoadingView(),
              HostExamPreviewError() => _PreviewError(
                sessionPublicId: sessionPublicId,
              ),
              HostExamPreviewFinished() => const SizedBox.shrink(),
              HostExamPreviewReady() => _PreviewReady(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.sessionPublicId});

  final String sessionPublicId;

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      icon: Icons.cloud_off,
      title: ExamPreviewStrings.previewErrorTitle,
      message: ExamPreviewStrings.previewErrorMessage,
      isError: true,
      children: [
        PrimaryButton(
          label: ExamPreviewStrings.retry,
          onPressed: () =>
              context.read<HostExamPreviewCubit>().load(sessionPublicId),
        ),
      ],
    );
  }
}

class _PreviewReady extends StatelessWidget {
  const _PreviewReady({required this.state});

  final HostExamPreviewReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HostExamPreviewCubit>();
    final item = state.currentItem;
    final model = PreviewTaskUiAdapter.adapt(item);
    final remaining = state.remainingSeconds;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ExamPreviewStrings.examHeading(state.snapshot.name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                ExamPreviewStrings.taskProgress(
                  state.currentIndex + 1,
                  state.snapshot.items.length,
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: AppDimensions.spacingMd),
                Text(ExamPreviewStrings.remainingTime(remaining)),
              ],
            ],
          ),
        ),
        Expanded(
          child: HostPreviewTaskDispatcher(
            key: ValueKey(item.snapshotItemPublicId),
            model: model,
            answer: cubit.answerFor(item),
            onAnswerChanged: cubit.setAnswer,
            onAudioPressed: item.audioUrl == null
                ? null
                : () => cubit.playAudio(item.audioUrl!),
            onStartRecording: cubit.startRecording,
            onStopRecording: cubit.stopRecording,
            isRecording: state.isRecording,
          ),
        ),
        HostPreviewNavigation(
          canGoBack: state.currentIndex > 0,
          isLast: state.currentIndex == state.snapshot.items.length - 1,
          isBusy: state.isTransitioning,
          onPrevious: cubit.previous,
          onNext: cubit.next,
          onFinish: cubit.finish,
        ),
      ],
    );
  }
}
