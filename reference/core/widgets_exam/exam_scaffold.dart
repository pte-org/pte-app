import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/widgets/exam/exam_app_bar.dart';
import 'package:aptis_app/core/widgets/exam/exam_bottom_bar.dart';
import 'package:aptis_app/core/widgets/exam/exam_content_frame.dart';

const Duration _tickInterval = Duration(seconds: 1);

class ExamScaffold extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final Widget body;
  final bool scrollableBody;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback onBack;
  final VoidCallback onFlag;
  final VoidCallback onNext;
  final bool showBack;

  const ExamScaffold({
    super.key,
    required this.currentScreen,
    required this.totalScreens,
    required this.timeRemaining,
    required this.body,
    required this.onBack,
    required this.onFlag,
    required this.onNext,
    this.scrollableBody = true,
    this.contentPadding,
    this.showBack = true,
  });

  @override
  State<ExamScaffold> createState() => _ExamScaffoldState();
}

class _ExamScaffoldState extends State<ExamScaffold> {
  bool _showTimer = true;
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timeRemaining;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(_tickInterval, (_) {
      if (_remaining <= Duration.zero) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= _tickInterval);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          ExamAppBar(
            currentScreen: widget.currentScreen,
            totalScreens: widget.totalScreens,
            timeRemaining: _remaining,
            showTimer: _showTimer,
            onToggleTimer: _toggleTimer,
          ),
          Expanded(
            child: widget.contentPadding != null
                ? ExamContentFrame(
                    scrollable: widget.scrollableBody,
                    padding: widget.contentPadding!,
                    child: widget.body,
                  )
                : ExamContentFrame(
                    scrollable: widget.scrollableBody,
                    child: widget.body,
                  ),
          ),
          ExamBottomBar(
            onBack: widget.onBack,
            onFlag: widget.onFlag,
            onNext: widget.onNext,
            showBack: widget.showBack,
          ),
        ],
      ),
    );
  }

  void _toggleTimer() {
    setState(() {
      _showTimer = !_showTimer;
    });
  }
}
