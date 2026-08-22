import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/duration_format.dart';

/// Purely presentational — takes [isRecording]/[elapsed]/[total] as props and
/// reads no BLoC/context itself, so it's trivially testable in isolation and
/// reusable. The waveform is explicitly decorative (a looping animation, not
/// real mic amplitude) — never wired to `AudioRecorderService`.
class ReadAloudRecordingIndicator extends StatefulWidget {
  const ReadAloudRecordingIndicator({super.key, required this.isRecording, required this.elapsed, required this.total});

  final bool isRecording;
  final Duration elapsed;
  final Duration total;

  @override
  State<ReadAloudRecordingIndicator> createState() => _ReadAloudRecordingIndicatorState();
}

class _ReadAloudRecordingIndicatorState extends State<ReadAloudRecordingIndicator> with TickerProviderStateMixin {
  // Purely local animation timing — not a shared visual dimension, so it
  // lives here rather than in AppDimensions (which is spacing/radius/font
  // size only).
  static const Duration _dotPulseDuration = Duration(milliseconds: 700);
  static const Duration _waveformLoopDuration = Duration(milliseconds: 900);

  late final AnimationController _dotController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(vsync: this, duration: _dotPulseDuration);
    _waveController = AnimationController(vsync: this, duration: _waveformLoopDuration);
    if (widget.isRecording) {
      _dotController.repeat(reverse: true);
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ReadAloudRecordingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording == oldWidget.isRecording) return;
    if (widget.isRecording) {
      _dotController.repeat(reverse: true);
      _waveController.repeat();
    } else {
      _dotController.stop();
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(animation: _dotController, isRecording: widget.isRecording),
        const SizedBox(width: AppDimensions.readAloudIndicatorGap),
        Text('${formatMmSs(widget.elapsed)} / ${formatMmSs(widget.total)}'),
        const SizedBox(width: AppDimensions.readAloudIndicatorGap),
        _Waveform(animation: _waveController, isRecording: widget.isRecording),
      ],
    );
  }
}

/// A record-dot whose opacity pulses while [isRecording]; static full
/// opacity otherwise. Scoped to its own `AnimatedBuilder` so only this dot
/// rebuilds on every animation tick, not the whole indicator row.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.animation, required this.isRecording});

  // Named alongside the animation-duration constants above for the same
  // reason — a decorative visual detail, not a magic number.
  static const double _minOpacity = 0.4;
  static const double _opacityRange = 0.6;

  final Animation<double> animation;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(opacity: isRecording ? _minOpacity + (animation.value * _opacityRange) : 1.0, child: child);
      },
      child: Container(
        width: AppDimensions.readAloudRecordDotSize,
        height: AppDimensions.readAloudRecordDotSize,
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
      ),
    );
  }
}

/// A decorative row of bars whose heights loop while [isRecording]; sit flat
/// at the minimum height otherwise. Never driven by real mic amplitude —
/// `AudioRecorderService` exposes no amplitude stream, and this widget takes
/// no dependency on it.
class _Waveform extends StatelessWidget {
  const _Waveform({required this.animation, required this.isRecording});

  static const int _barCount = 5;

  final Animation<double> animation;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_barCount, (index) => _bar(index)),
        );
      },
    );
  }

  Widget _bar(int index) {
    final height = isRecording ? _animatedBarHeight(index) : AppDimensions.readAloudWaveformBarMinHeight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.readAloudWaveformBarSpacing / 2),
      child: Container(
        width: AppDimensions.readAloudWaveformBarWidth,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.readAloudWaveformBarWidth / 2),
        ),
      ),
    );
  }

  /// Each bar is offset along the same loop so they don't all move in
  /// lockstep — purely decorative, no meaning attached to the exact phase.
  double _animatedBarHeight(int index) {
    final phase = animation.value * 2 * math.pi + (index * math.pi / _barCount);
    final wave = (math.sin(phase) + 1) / 2; // normalize sin's [-1, 1] to [0, 1]
    final range = AppDimensions.readAloudWaveformBarMaxHeight - AppDimensions.readAloudWaveformBarMinHeight;
    return AppDimensions.readAloudWaveformBarMinHeight + (wave * range);
  }
}
