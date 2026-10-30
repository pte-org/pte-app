import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/components/subheader_banner.dart';
import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recording_level_waveform.dart';
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
    this.volumeService,
    this.onComplete,
  });

  final AudioRecorderService recorder;
  final DeviceCheckAudioPlayer player;
  final VolumeService? volumeService;

  /// Called once after the student confirms both the microphone and sound
  /// checks. Null for the standalone developer preview.
  final VoidCallback? onComplete;

  @override
  State<TestMicAndSoundScreen> createState() => _TestMicAndSoundScreenState();
}

class _TestMicAndSoundScreenState extends State<TestMicAndSoundScreen> {
  late final DeviceCheckCubit _cubit;
  late final VolumeService _volumeService;
  late final bool _ownsVolumeService;

  @override
  void initState() {
    super.initState();
    _cubit = DeviceCheckCubit(recorder: widget.recorder, player: widget.player);
    if (widget.volumeService != null) {
      _volumeService = widget.volumeService!;
      _ownsVolumeService = false;
    } else if (GetIt.instance.isRegistered<VolumeService>()) {
      _volumeService = GetIt.instance<VolumeService>();
      _ownsVolumeService = false;
    } else {
      _volumeService = VolumeService();
      _ownsVolumeService = true;
    }
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    unawaited(widget.player.close());
    if (_ownsVolumeService) _volumeService.dispose();
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
        child: ExamShell(
          header: const ExamHeaderBar(
            examTitle: ExamChromeConfig.defaultExamTitle,
            candidateName: 'Candidate',
            candidateId: ExamChromeConfig.unavailableCandidateId,
            itemLabel: DeviceCheckStrings.screenSectionLabel,
            timeLabel: '--:--',
          ),
          body: ColoredBox(
            color: AppColors.surfaceCanvas,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.contentMaxWidth,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: BlocBuilder<DeviceCheckCubit, DeviceCheckState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SubheaderBanner(
                            title: DeviceCheckStrings.screenTitle,
                            subtitle: DeviceCheckStrings.screenSectionLabel,
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),
                          _DeviceCheckHeader(state: state),
                          const SizedBox(height: AppDimensions.spacingMd),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final sideBySide =
                                  constraints.maxWidth >=
                                  AppDimensions.templateSideBySideBreakpoint;
                              final microphone = _DeviceCheckPanel(
                                child: _MicSection(state: state),
                              );
                              final sound = _DeviceCheckPanel(
                                child: _SoundSection(
                                  state: state,
                                  volumeService: _volumeService,
                                ),
                              );
                              return sideBySide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: microphone),
                                        const SizedBox(
                                          width: AppDimensions.spacingMd,
                                        ),
                                        Expanded(child: sound),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        microphone,
                                        const SizedBox(
                                          height: AppDimensions.spacingMd,
                                        ),
                                        sound,
                                      ],
                                    );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          footer: const ExamFooterBar(navigationActions: SizedBox.shrink()),
        ),
      ),
    );
  }
}

class _DeviceCheckPanel extends StatelessWidget {
  const _DeviceCheckPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusDefault),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: AppTypography.bodyRegular.copyWith(color: AppColors.textPrimary),
        child: child,
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusDefault),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DeviceCheckStrings.screenSubtitle,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DeviceCheckStrings.progressLabel,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$completedChecks/2',
                  style: AppTypography.labelMeta.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
          style: AppTypography.bodyRegular.copyWith(
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
          style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        const Text(
          DeviceCheckStrings.micInstructionText,
          style: AppTypography.bodyRegular,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
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
            PrimaryButton(
              label: DeviceCheckStrings.playMyRecordingButtonLabel,
              onPressed: canPlay ? cubit.playMicRecording : null,
            ),
          ],
        ),
        if (micPhase == MicCheckPhase.recording) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          RecordingLevelWaveform(levels: cubit.inputLevels),
        ],
        if (state.micErrorMessage != null) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            state.micErrorMessage!,
            style: AppTypography.bodyRegular.copyWith(color: AppColors.error),
          ),
        ],
        if (micPhase == MicCheckPhase.playedBack &&
            state.micConfirmedHeardClearly == null) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          const Text(
            DeviceCheckStrings.micConfirmPrompt,
            style: AppTypography.bodyBold,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Wrap(
            spacing: AppDimensions.spacingSm,
            runSpacing: AppDimensions.spacingSm,
            children: [
              PrimaryButton(
                label: DeviceCheckStrings.confirmYesLabel,
                onPressed: () => cubit.confirmMicHeard(true),
              ),
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
  const _SoundSection({required this.state, required this.volumeService});

  final DeviceCheckState state;
  final VolumeService volumeService;

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
          style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        const Text(
          DeviceCheckStrings.soundInstructionText,
          style: AppTypography.bodyRegular,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        PrimaryButton(
          label: DeviceCheckStrings.playTestSoundButtonLabel,
          onPressed: canPlayTestSound ? cubit.playTestSound : null,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        _VolumeControl(volumeService: volumeService),
        if (soundPhase == SoundCheckPhase.played &&
            state.soundConfirmedHeardClearly == null) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          const Text(
            DeviceCheckStrings.soundConfirmPrompt,
            style: AppTypography.bodyBold,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Wrap(
            spacing: AppDimensions.spacingSm,
            runSpacing: AppDimensions.spacingSm,
            children: [
              PrimaryButton(
                label: DeviceCheckStrings.confirmYesLabel,
                onPressed: () => cubit.confirmSoundHeard(true),
              ),
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

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.volumeService});

  final VolumeService volumeService;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_up, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: volumeService,
            builder: (context, volume, _) {
              return Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                activeColor: AppColors.brandPrimary,
                onChanged: (v) => volumeService.value = v,
              );
            },
          ),
        ),
      ],
    );
  }
}
