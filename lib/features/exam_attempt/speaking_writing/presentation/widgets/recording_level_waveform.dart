import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// Level (dBFS) at or below which the waveform shows a flat baseline —
/// roughly a quiet room's noise floor.
const double _silenceFloorDbfs = -60.0;

/// Level (dBFS) that fills the full bar height. Well below digital full
/// scale (0 dBFS) because normal speech into a headset mic peaks around
/// -40 to -20 dBFS — scaling to 0 dBFS made a working headset look barely
/// audible.
const double _fullHeightDbfs = -20.0;

/// Enough bars to fill a wide card; older levels scroll off the left edge.
const int _historyLength = 240;

/// Maps a mic peak level in dBFS to a `0.0`–`1.0` bar height, linear in dB
/// between [_silenceFloorDbfs] and [_fullHeightDbfs]. Non-finite input (the
/// native recorder reports `-inf` for pure digital silence) maps to `0.0`.
double normalizeInputLevel(double dbfs) {
  if (dbfs.isNaN) return 0.0;
  return ((dbfs - _silenceFloorDbfs) / (_fullHeightDbfs - _silenceFloorDbfs))
      .clamp(0.0, 1.0);
}

/// Scrolling bar waveform of the live mic level, newest bar on the right —
/// shown while an exam answer is recording so the candidate can see their
/// mic is actually picking up sound (e.g. that a headset mic, not a distant
/// laptop mic, is in use).
class RecordingLevelWaveform extends StatefulWidget {
  const RecordingLevelWaveform({super.key, required this.levels});

  /// Live mic levels in dBFS — see `AudioRecorderService.inputLevels`.
  final Stream<double> levels;

  @override
  State<RecordingLevelWaveform> createState() => _RecordingLevelWaveformState();
}

class _RecordingLevelWaveformState extends State<RecordingLevelWaveform> {
  List<double> _history = List<double>.filled(_historyLength, 0.0);
  StreamSubscription<double>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.levels.listen(_onLevel);
  }

  @override
  void didUpdateWidget(RecordingLevelWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levels != widget.levels) {
      unawaited(_subscription?.cancel());
      _subscription = widget.levels.listen(_onLevel);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _onLevel(double dbfs) {
    setState(() {
      _history = [..._history.skip(1), normalizeInputLevel(dbfs)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: SpeakingWritingStrings.recordingInputLevelSemanticsLabel,
      child: SizedBox(
        width: double.infinity,
        height: AppDimensions.recordingWaveformHeight,
        child: CustomPaint(
          painter: _WaveformPainter(
            history: _history,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.history, required this.color});

  final List<double> history;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = AppDimensions.recordingWaveformBarWidth;
    const slot = barWidth + AppDimensions.recordingWaveformBarGap;
    final paint = Paint()..color = color;
    final centerY = size.height / 2;
    final visibleBars = math.min(history.length, (size.width / slot).floor());
    for (var i = 0; i < visibleBars; i++) {
      final level = history[history.length - 1 - i];
      final barHeight = math.max(barWidth, level * size.height);
      final centerX = size.width - slot * i - barWidth / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: barWidth,
            height: barHeight,
          ),
          const Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      !identical(oldDelegate.history, history) || oldDelegate.color != color;
}
