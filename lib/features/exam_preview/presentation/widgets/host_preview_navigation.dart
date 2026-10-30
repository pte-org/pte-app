import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:flutter/material.dart';

import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_navigation_actions.dart';

class HostPreviewNavigation extends StatelessWidget {
  const HostPreviewNavigation({
    super.key,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isBusy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ExamFooterBar(
        navigationActions: ExamNavigationActions(
          showPrevious: true,
          onPrevious: isBusy ? null : onPrevious,
          onNext: isBusy ? null : onNext,
          nextLabel: ExamPreviewStrings.next,
          nextLoading: isBusy,
        ),
      ),
    );
  }
}
