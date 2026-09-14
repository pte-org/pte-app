import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';

/// Stateless shell used by every exam task. Feature code owns state and passes
/// the already-bound header, body and footer into this widget.
class ExamShell extends StatelessWidget {
  const ExamShell({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
    this.topNotice,
  });

  final Widget header;
  final Widget body;
  final Widget footer;
  final Widget? topNotice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Column(
        children: [
          ?topNotice,
          SizedBox(height: AppDimensions.examHeaderHeight, child: header),
          Expanded(child: body),
          SizedBox(height: AppDimensions.examFooterHeight, child: footer),
        ],
      ),
    );
  }
}
