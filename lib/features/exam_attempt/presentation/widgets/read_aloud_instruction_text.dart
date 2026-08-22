import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Italic instruction line shown above the "Recorded Answer" status card —
/// templated from [responseSeconds], never a hardcoded "40 seconds", since
/// every task's response window differs. Rendered during both prep and
/// response phases (never disappears once shown).
class ReadAloudInstructionText extends StatelessWidget {
  const ReadAloudInstructionText({super.key, required this.responseSeconds});

  final int responseSeconds;

  @override
  Widget build(BuildContext context) {
    return Text(
      _instructionText(),
      style: const TextStyle(color: AppColors.textPrimary, fontStyle: FontStyle.italic),
    );
  }

  String _instructionText() {
    return '${AppStrings.readAloudInstructionPrefix}$responseSeconds'
        '${AppStrings.readAloudInstructionMiddle}$responseSeconds'
        '${AppStrings.readAloudInstructionSuffix}';
  }
}
