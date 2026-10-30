import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'preview_media_status.dart';
import '../../data/preview_audio_session.dart';
import '../../data/preview_playback_state.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';

class HostPreviewStimulus extends StatelessWidget {
  const HostPreviewStimulus({
    super.key,
    required this.model,
    this.onAudioPressed,
    this.imageOnly,
    this.audioPosition,
    this.mediaSession,
    this.excludeAudio = false,
    this.showEmptyState = true,
    this.onlyAudio = false,
  });

  final PreviewTaskUiModel model;
  final VoidCallback? onAudioPressed;
  final bool? imageOnly;
  final Stream<Duration>? audioPosition;
  final PreviewAudioSession? mediaSession;
  final bool excludeAudio;
  final bool showEmptyState;
  final bool onlyAudio;

  bool get _isListening => model.meta?.section == 'LISTENING';

  bool get _listeningMultiple =>
      TaskTypeCodes.canonicalize(model.taskType) ==
      TaskTypeCodes.mcListeningMultiple;

  bool get _listeningChoice =>
      _listeningMultiple ||
      TaskTypeCodes.canonicalize(model.taskType) ==
          TaskTypeCodes.mcListeningSingle;

  @override
  Widget build(BuildContext context) {
    final filteredParts = model.stimulus.parts
        .where((part) {
          if (onlyAudio && part.kind != StimulusPartKind.audio) return false;
          if (excludeAudio && part.kind == StimulusPartKind.audio) return false;
          if (imageOnly != null &&
              (part.kind == StimulusPartKind.image) != imageOnly) {
            return false;
          }
          return true;
        })
        .where((part) => part.content.isNotEmpty)
        .toList(growable: false);
    if (filteredParts.isEmpty) {
      return showEmptyState
          ? const ExamStatusBlock(
              title: ExamPreviewStrings.noStimulusTitle,
              message: ExamPreviewStrings.noStimulusMessage,
            )
          : const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < filteredParts.length; index++) ...[
          _part(filteredParts[index]),
          if (index < filteredParts.length - 1)
            const SizedBox(height: AppDimensions.spacingMd),
        ],
      ],
    );
  }

  Widget _part(StimulusPart part) {
    return switch (part.kind) {
      StimulusPartKind.audio when mediaSession != null =>
        ValueListenableBuilder<PreviewPlaybackState>(
          valueListenable: mediaSession!.playback,
          builder: (context, state, _) {
            final phase = state.phase;
            final label = switch (phase) {
              PreviewPlaybackPhase.idle => ExamPreviewStrings.audioReady,
              PreviewPlaybackPhase.loading => ExamPreviewStrings.audioLoading,
              PreviewPlaybackPhase.playing => ExamPreviewStrings.playing,
              PreviewPlaybackPhase.paused => ExamPreviewStrings.paused,
              PreviewPlaybackPhase.stopped => ExamPreviewStrings.stopped,
              PreviewPlaybackPhase.completed => ExamPreviewStrings.completed,
              PreviewPlaybackPhase.failed => ExamPreviewStrings.audioFailed,
            };
            final canToggle =
                mediaSession!.canControlPlayback &&
                (phase == PreviewPlaybackPhase.playing ||
                    phase == PreviewPlaybackPhase.paused);
            final primaryAction = phase == PreviewPlaybackPhase.idle
                ? onAudioPressed
                : canToggle
                ? mediaSession!.togglePlaybackPause
                : null;
            return AudioListeningStatusCard(
              statusLabel: label,
              progress: state.progress,
              playing: phase == PreviewPlaybackPhase.playing,
              timeLabel: state.duration == null
                  ? null
                  : '${formatPteAudioDuration(state.position)}${AppStrings.audioTimeSeparator}${formatPteAudioDuration(state.duration!)}',
              onPauseResume: primaryAction,
              onStop: !_isListening && canToggle
                  ? mediaSession!.stopPlaybackByHost
                  : null,
              onReplay:
                  (phase == PreviewPlaybackPhase.completed ||
                          (!_isListening &&
                              phase == PreviewPlaybackPhase.stopped)) &&
                      mediaSession!.canReplayPlayback
                  ? mediaSession!.replayPlayback
                  : null,
            );
          },
        ),
      StimulusPartKind.audio => StreamBuilder<Duration>(
        stream: audioPosition,
        builder: (context, snapshot) {
          final total = model.item.audioDurationSeconds ?? 0;
          final elapsed = snapshot.data?.inMilliseconds ?? 0;
          final completed = total > 0 && elapsed >= total * 1000;
          final hasPosition = snapshot.hasData;
          return AudioListeningStatusCard(
            statusLabel: completed
                ? ExamPreviewStrings.completed
                : hasPosition
                ? ExamPreviewStrings.playing
                : ExamPreviewStrings.audioReady,
            progress: total > 0
                ? (elapsed / (total * 1000)).clamp(0.0, 1.0)
                : 0,
            playing: hasPosition && !completed,
            onPauseResume: hasPosition ? null : onAudioPressed,
          );
        },
      ),
      StimulusPartKind.image => ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDimensions.spacingXs),
        ),
        child: Image.network(
          part.content,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const PreviewMediaStatus(
                title: ExamPreviewStrings.imageErrorTitle,
                message: ExamPreviewStrings.imageErrorMessage,
                isError: true,
              ),
        ),
      ),
      StimulusPartKind.passage ||
      StimulusPartKind.text ||
      StimulusPartKind.transcript => SelectableText(
        part.content,
        style:
            (_listeningChoice
                    ? AppTypography.examAnswer
                    : AppTypography.bodyPassage)
                .copyWith(color: AppColors.textPrimary),
      ),
    };
  }
}
