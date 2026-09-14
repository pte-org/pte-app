import 'package:flutter/material.dart';

import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';

/// Feature adapter for the pure, forward-only design footer.
class ExamBottomBar extends StatelessWidget {
  const ExamBottomBar({super.key, this.action, this.onSaveAndExit});

  final Widget? action;
  final VoidCallback? onSaveAndExit;

  @override
  Widget build(BuildContext context) {
    return ExamFooterBar(nextAction: action, onSaveAndExit: onSaveAndExit);
  }
}
