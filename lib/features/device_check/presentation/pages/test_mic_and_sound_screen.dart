import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/device_check/constants/device_check_strings.dart';
import 'package:pte_app/features/device_check/domain/device_check_audio_player.dart';
import 'package:pte_app/features/device_check/presentation/cubit/device_check_cubit.dart';
import 'package:pte_app/features/device_check/presentation/cubit/device_check_state.dart';

/// A pre-exam screen where a candidate checks their microphone
/// (record + play back their own voice, confirm Yes/No) and separately
/// checks their sound (play a bundled test clip, confirm Yes/No) before an
/// exam. No timer, no `ExamScaffold`, no exam-attempt machinery — every
/// transition is a direct response to a button tap. `kDebugMode`-gated dev
/// entry point (see `lib/app.dart`).
///
/// [player] is taken as a constructor param (like [recorder]) rather than
/// constructed internally, so widget tests can substitute a mock. Callers
/// construct the real `DeviceCheckAudioPlayerImpl`; it is not GetIt-registered
/// because the player is a screen-scoped resource.
class TestMicAndSoundScreen extends StatefulWidget {
  const TestMicAndSoundScreen({
    super.key,
    required this.recorder,
    required this.player,
    this.onComplete,
  });

  final AudioRecorderService recorder;
  final DeviceCheckAudioPlayer player;

  /// Called once after the student confirms both the microphone and sound
  /// checks. Null for the standalone developer preview.
  final VoidCallback? onComplete;

  @override
  State<TestMicAndSoundScreen> createState() => _TestMicAndSoundScreenState();
}

class _TestMicAndSoundScreenState extends State<TestMicAndSoundScreen> {
  late final DeviceCheckCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DeviceCheckCubit(recorder: widget.recorder, player: widget.player);
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    unawaited(widget.player.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<DeviceCheckCubit, DeviceCheckState>(
        listenWhen: (previous, state) =>
            !previous.isComplete && state.isComplete,
        listener: (_, _) => widget.onComplete?.call(),
        child: Scaffold(
          appBar: AppBar(title: const Text(DeviceCheckStrings.screenTitle)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingMedium),
              child: BlocBuilder<DeviceCheckCubit, DeviceCheckState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DeviceCheckHeader(state: state),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppDimensions.spacingMedium,
                          ),
                          child: _MicSection(state: state),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppDimensions.spacingMedium,
                          ),
                          child: _SoundSection(state: state),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCheckHeader extends StatelessWidget {
  const _DeviceCheckHeader({required this.state});

  final DeviceCheckState state;

  @override
  Widget build(BuildContext context) {
    final completedChecks = [
      state.micConfirmedHeardClearly == true,
      state.soundConfirmedHeardClearly == true,
    ].where((completed) => completed).length;
    final progress = completedChecks / 2;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surfaceSubtle,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DeviceCheckStrings.screenSubtitle,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DeviceCheckStrings.progressLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedChecks/2',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: AppDimensions.spacingMedium),
            Wrap(
              spacing: AppDimensions.spacingMd,
              runSpacing: AppDimensions.spacingSm,
              children: [
                _CheckStatus(
                  label: DeviceCheckStrings.microphoneReadyLabel,
                  complete: state.micConfirmedHeardClearly == true,
                ),
                _CheckStatus(
                  label: DeviceCheckStrings.soundReadyLabel,
                  complete: state.soundConfirmedHeardClearly == true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckStatus extends StatelessWidget {
  const _CheckStatus({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          complete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: complete ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Text(
          label,
          style: TextStyle(
            color: complete ? AppColors.success : AppColors.textSecondary,
            fontWeight: complete ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _MicSection extends StatelessWidget {
  const _MicSection({required this.state});

  final DeviceCheckState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceCheckCubit>();
    final micPhase = state.micPhase;
    // Also disabled while the sound sub-flow is mid-playback — both share
    // one underlying player; the cubit's reentrancy guard is the actual
    // correctness boundary, this is a UI-level nicety so the button
    // doesn't look tappable when it would be a no-op.
    final canPlay =
        (micPhase == MicCheckPhase.recorded ||
            micPhase == MicCheckPhase.playedBack) &&
        state.soundPhase != SoundCheckPhase.playing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DeviceCheckStrings.micSectionTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        const Text(
          DeviceCheckStrings.micInstructionText,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Row(
          children: [
            if (micPhase == MicCheckPhase.recording)
              PrimaryButton(
                label: DeviceCheckStrings.stopButtonLabel,
                onPressed: cubit.stopMicRecording,
              )
            else
              PrimaryButton(
                label: DeviceCheckStrings.recordButtonLabel,
                onPressed: micPhase == MicCheckPhase.idle
                    ? cubit.startMicRecording
                    : null,
              ),
            const SizedBox(width: AppDimensions.spacingMedium),
            PrimaryButton(
              label: DeviceCheckStrings.playMyRecordingButtonLabel,
              onPressed: canPlay ? cubit.playMicRecording : null,
            ),
          ],
        ),
        if (state.micErrorMessage != null) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            state.micErrorMessage!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
        if (micPhase == MicCheckPhase.playedBack &&
            state.micConfirmedHeardClearly == null) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          const Text(
            DeviceCheckStrings.micConfirmPrompt,
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              PrimaryButton(
                label: DeviceCheckStrings.confirmYesLabel,
                onPressed: () => cubit.confirmMicHeard(true),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              PrimaryButton(
                label: DeviceCheckStrings.confirmNoLabel,
                onPressed: () => cubit.confirmMicHeard(false),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SoundSection extends StatelessWidget {
  const _SoundSection({required this.state});

  final DeviceCheckState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceCheckCubit>();
    final soundPhase = state.soundPhase;
    // Also disabled while the mic sub-flow is mid-playback — see
    // `_MicSection`'s matching comment on `canPlay`.
    final canPlayTestSound =
        soundPhase != SoundCheckPhase.playing &&
        state.micPhase != MicCheckPhase.playingBack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DeviceCheckStrings.soundSectionTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        const Text(
          DeviceCheckStrings.soundInstructionText,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        PrimaryButton(
          label: DeviceCheckStrings.playTestSoundButtonLabel,
          onPressed: canPlayTestSound ? cubit.playTestSound : null,
        ),
        if (soundPhase == SoundCheckPhase.played &&
            state.soundConfirmedHeardClearly == null) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          const Text(
            DeviceCheckStrings.soundConfirmPrompt,
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              PrimaryButton(
                label: DeviceCheckStrings.confirmYesLabel,
                onPressed: () => cubit.confirmSoundHeard(true),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              PrimaryButton(
                label: DeviceCheckStrings.confirmNoLabel,
                onPressed: () => cubit.confirmSoundHeard(false),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
