import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recorded_answer_status_card.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import '../../data/preview_audio_session.dart';
import '../../data/preview_playback_state.dart';
import '../model/preview_task_ui_model.dart';
import 'package:pte_app/core/widgets/components/pte_status_audio_panel.dart';
import 'package:pte_app/core/widgets/templates/status_speaking_task_frame.dart';

/// The preview equivalent of the candidate audio-prompt surface.
///
/// PTE presents the prompt player and the candidate recorder as one changing
/// surface. Host preview must keep that same sequence while retaining its
/// in-memory media controls, so the panel is driven by [PreviewAudioSession]
/// and the preview timer instead of an exam-attempt cubit.
class HostPreviewAudioPromptPanel extends StatelessWidget {
  const HostPreviewAudioPromptPanel({
    super.key,
    required this.model,
    this.mediaSession,
    this.onAudioPressed,
    this.remainingSeconds,
    this.isPreparing = false,
    this.recordingUnavailable = false,
    this.inputLevels,
    this.audioPosition,
    this.isRecording = false,
    this.isRecordingPaused = false,
    this.onRecordingPauseResume,
    this.onRecordingStop,
  });

  final PreviewTaskUiModel model;
  final PreviewAudioSession? mediaSession;
  final VoidCallback? onAudioPressed;
  final int? remainingSeconds;
  final bool isPreparing;
  final bool recordingUnavailable;
  final Stream<double>? inputLevels;
  final Stream<Duration>? audioPosition;
  final bool isRecording;
  final bool isRecordingPaused;
  final VoidCallback? onRecordingPauseResume;
  final VoidCallback? onRecordingStop;

  @override
  Widget build(BuildContext context) {
    final session = mediaSession;
    if (session != null) {
      return ValueListenableBuilder<PreviewPlaybackState>(
        valueListenable: session.playback,
        builder: (context, playback, _) => _buildPanel(playback),
      );
    }
    return StreamBuilder<Duration>(
      stream: audioPosition,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = model.item.audioDurationSeconds == null
            ? null
            : Duration(seconds: model.item.audioDurationSeconds!);
        final completed = duration != null && position >= duration;
        final playback = PreviewPlaybackState(
          phase: completed
              ? PreviewPlaybackPhase.completed
              : audioPosition == null
              ? PreviewPlaybackPhase.idle
              : PreviewPlaybackPhase.playing,
          position: position,
          duration: duration,
        );
        return _buildPanel(playback);
      },
    );
  }

  Widget _buildPanel(PreviewPlaybackState playback) {
    if (usesStatusAudioPanels(model.taskType)) {
      return PteStatusAudioPair(
        player: _buildPlayer(playback),
        recorder: _buildRecorder(),
      );
    }
    if (_shouldShowRecorder(playback)) {
      return _buildRecorder();
    }
    return _buildPlayer(playback);
  }

  bool _shouldShowRecorder(PreviewPlaybackState playback) {
    if (recordingUnavailable || isRecording || !isPreparing) return true;
    return playback.phase == PreviewPlaybackPhase.completed;
  }

  Widget _buildPlayer(PreviewPlaybackState playback) {
    final phase = playback.phase;
    return AudioListeningStatusCard(
      statusStyle: usesStatusAudioPanels(model.taskType),
      statusLabel: _playerStatusLabel(phase),
      progress: playback.progress,
      playing: phase == PreviewPlaybackPhase.playing,
      timeLabel: playback.duration == null
          ? null
          : '${formatPteAudioDuration(playback.position)}'
                '${AppStrings.audioTimeSeparator}'
                '${formatPteAudioDuration(playback.duration!)}',
    );
  }

  Widget _buildRecorder() {
    final seconds = remainingSeconds ?? model.item.prepSeconds;
    final total = isPreparing
        ? model.item.prepSeconds
        : model.item.responseSeconds;
    final label = recordingUnavailable
        ? SpeakingWritingStrings.recordingMicrophoneUnavailableLabel
        : isRecordingPaused
        ? ExamPreviewStrings.paused
        : isPreparing
        ? '${SpeakingWritingStrings.recordingBeginningInPrefix}$seconds'
              '${SpeakingWritingStrings.recordingBeginningInSuffix}'
        : seconds == 0 && !isRecording
        ? ExamPreviewStrings.completed
        : '${SpeakingWritingStrings.recordingInProgressPrefix}$seconds'
              '${SpeakingWritingStrings.recordingInProgressSuffix}';
    return RecordedAnswerStatusCard(
      statusStyle: usesStatusAudioPanels(model.taskType),
      isPreparing: isPreparing && !recordingUnavailable && !isRecording,
      statusLabel: label,
      progress: isPreparing || total <= 0
          ? 0
          : ((total - seconds) / total).clamp(0.0, 1.0),
      inputLevels: isRecording && !isRecordingPaused ? inputLevels : null,
      playing: isRecording && !isRecordingPaused,
      onPauseResume: isRecording ? onRecordingPauseResume : null,
      onStop: isRecording ? onRecordingStop : null,
      timeLabel:
          '${formatPteAudioDuration(Duration(seconds: isPreparing ? 0 : (total - seconds).clamp(0, total > 0 ? total : 0)))}'
          '${AppStrings.audioTimeSeparator}'
          '${formatPteAudioDuration(Duration(seconds: model.item.responseSeconds))}',
    );
  }

  String _playerStatusLabel(PreviewPlaybackPhase phase) => switch (phase) {
    PreviewPlaybackPhase.idle => ExamPreviewStrings.audioReady,
    PreviewPlaybackPhase.loading => ExamPreviewStrings.audioLoading,
    PreviewPlaybackPhase.playing => ExamPreviewStrings.playing,
    PreviewPlaybackPhase.paused => ExamPreviewStrings.paused,
    PreviewPlaybackPhase.stopped => ExamPreviewStrings.stopped,
    PreviewPlaybackPhase.completed => ExamPreviewStrings.completed,
    PreviewPlaybackPhase.failed => ExamPreviewStrings.audioFailed,
  };
}
