import 'package:flutter/material.dart';

import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';

/// Feature adapter for the shared exam footer.
class ExamBottomBar extends StatelessWidget {
  const ExamBottomBar({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ExamFooterBar(
      navigationActions: action,
    );
  }
}
