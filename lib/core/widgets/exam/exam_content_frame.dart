import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';

class ExamContentFrame extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const ExamContentFrame({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.examPagePaddingHorizontal,
      vertical: AppDimensions.examPagePaddingVertical,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      color: AppColors.backgroundLight,
      child: Padding(padding: padding, child: child),
    );

    if (!scrollable) {
      return content;
    }

    return SingleChildScrollView(child: content);
  }
}
