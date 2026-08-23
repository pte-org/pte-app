import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';

/// Countdown display driven by an injected [Ticker] (defaults to a one-second
/// periodic [Timer]). `Widget.build` only reads [_remaining]; passing a
/// fake `Ticker` makes the widget's remaining value controllable from a
/// widget test without spinning real time. Cancels the ticker on dispose.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.totalSeconds, this.onExpired, Ticker? ticker})
    : _ticker = ticker;

  final int totalSeconds;
  final VoidCallback? onExpired;
  final Ticker? _ticker;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

typedef Ticker = Stream<int> Function(Duration period);

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    final stream = (widget._ticker ?? _defaultTicker)(const Duration(seconds: 1));
    _sub = stream.listen(_onTick);
  }

  void _onTick(int _) {
    if (!mounted) return;
    setState(() {
      if (_remaining > 0) _remaining -= 1;
    });
    if (_remaining == 0) {
      _sub?.cancel();
      widget.onExpired?.call();
    }
  }

  Stream<int> _defaultTicker(Duration period) {
    return Stream<int>.periodic(period, (c) => c);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _format() {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${AppStrings.countdownLabelPrefix}${_format()}',
          style: const TextStyle(
            color: AppColors.countdownTextColor,
            fontWeight: FontWeight.bold,
            fontSize: AppDimensions.countdownTimerFontSize,
          ),
        ),
      ],
    );
  }
}
