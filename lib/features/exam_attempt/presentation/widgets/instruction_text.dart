import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Italic instruction line shown above a task's status card(s) — plain
/// text-driven; the caller (e.g. `ReadAloudScreen`, `RepeatSentenceScreen`)
/// computes its own string (templated from task fields, or fixed).
class InstructionText extends StatelessWidget {
  const InstructionText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.textPrimary, fontStyle: FontStyle.italic));
  }
}
