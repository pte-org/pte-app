import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';

enum SpeakingMicState {
  idle,
  recording,
  completed,
}

class SpeakingMicrophoneButton extends StatefulWidget {
  final SpeakingMicState state;
  final VoidCallback? onPressed;
  final double? dimension;
  final double? iconSize;
  final double? borderWidth;

  const SpeakingMicrophoneButton({
    super.key,
    required this.state,
    this.onPressed,
    this.dimension,
    this.iconSize,
    this.borderWidth,
  });

  @override
  State<SpeakingMicrophoneButton> createState() =>
      _SpeakingMicrophoneButtonState();
}

class _SpeakingMicrophoneButtonState extends State<SpeakingMicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(SpeakingMicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.state == SpeakingMicState.recording) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.state == SpeakingMicState.completed;
    final bool isRecording = widget.state == SpeakingMicState.recording;

    Color buttonColor;
    Color iconColor;
    IconData iconData;

    switch (widget.state) {
      case SpeakingMicState.recording:
        buttonColor = Colors.red.shade50;
        iconColor = Colors.red;
        iconData = Icons.stop;
        break;
      case SpeakingMicState.completed:
        buttonColor = Colors.green.shade50;
        iconColor = Colors.green;
        iconData = Icons.check_circle_outline;
        break;
      case SpeakingMicState.idle:
        buttonColor = AppColors.backgroundLight;
        iconColor = AppColors.textDark;
        iconData = Icons.mic_none;
        break;
    }

    final double activeDimension =
        widget.dimension ?? AppDimensions.speakingMicButtonSize;
    final double bw = widget.borderWidth ?? AppDimensions.speakingMicBorderWidth;

    final Widget button = SizedBox.square(
      dimension: activeDimension,
      child: Material(
        color: buttonColor,
        shape: CircleBorder(
          side: BorderSide(
            color: isRecording
                ? Colors.red
                : (isCompleted ? Colors.green : AppColors.textDark),
            width: bw,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isCompleted ? null : widget.onPressed,
          child: Icon(
            iconData,
            size: widget.iconSize ?? AppDimensions.speakingMicIconSize,
            color: iconColor,
          ),
        ),
      ),
    );

    if (!isRecording) return button;

    // Ripple pulse rings when recording
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Transform.scale(
              scale: _pulseScale.value,
              child: Opacity(
                opacity: _pulseOpacity.value,
                child: Container(
                  width: activeDimension,
                  height: activeDimension,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            // Inner pulse ring (offset by half cycle)
            Transform.scale(
              scale: Tween<double>(begin: 1.0, end: 1.3)
                  .evaluate(CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeOut)),
              child: Opacity(
                opacity: Tween<double>(begin: 0.4, end: 0.0)
                    .evaluate(CurvedAnimation(
                        parent: _pulseController, curve: Curves.easeOut)),
                child: Container(
                  width: activeDimension,
                  height: activeDimension,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: button,
    );
  }
}
