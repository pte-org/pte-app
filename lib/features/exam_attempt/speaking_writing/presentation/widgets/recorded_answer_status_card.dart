import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';
import 'package:pte_app/core/widgets/components/pte_status_audio_panel.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recording_level_waveform.dart';

/// Purely presentational "Recorded Answer" status card — takes an already
/// resolved [statusLabel] and [progress] as props, no BLoC/context reads of
/// its own, so it's trivially testable in isolation and reusable. Shared by
/// every auto-record speaking task's screen (Read Aloud, Repeat Sentence) —
/// not Read-Aloud-specific despite having originally lived under that name.
class RecordedAnswerStatusCard extends StatelessWidget {
  const RecordedAnswerStatusCard({
    super.key,
    required this.statusLabel,
    required this.progress,
    this.inputLevels,
    this.timeLabel,
    this.title = AppStrings.audioRecorderTitle,
    this.softAppearance = true,
    this.onPauseResume,
    this.onStop,
    this.playing = true,
    this.isPreparing = false,
    this.statusStyle = false,
  });

  final String statusLabel;

  /// `0.0`–`1.0`, clamped by the caller — how much of the current
  /// prep/response window has elapsed.
  final double progress;

  /// Live mic levels (dBFS); when set, a [RecordingLevelWaveform] is shown
  /// in the right-side meter. Callers pass it only while actually recording.
  final Stream<double>? inputLevels;
  final String? timeLabel;
  final String title;
  final bool softAppearance;
  final VoidCallback? onPauseResume;
  final VoidCallback? onStop;
  final bool playing;
  final bool isPreparing;
  final bool statusStyle;

  @override
  Widget build(BuildContext context) {
    if (statusStyle) {
      return PteStatusAudioPanel(
        isRecorder: true,
        statusLabel: statusLabel,
        progress: progress,
      );
    }
    return PteAudioPanel(
      variant: PteAudioPanelVariant.recorder,
      title: title,
      statusLabel: statusLabel,
      progress: progress,
      timeLabel: timeLabel,
      onPrimaryAction: onPauseResume,
      onStop: onStop,
      playing: !isPreparing && playing,
      isPreparingRecording: isPreparing,
      sideIndicator: inputLevels == null
          ? null
          : RecordingLevelWaveform(levels: inputLevels!, compact: true),
    );
  }
}
