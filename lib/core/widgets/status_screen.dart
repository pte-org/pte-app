import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/status_banner.dart';

/// Full-screen status page outside the exam shell (exam completed, unable to
/// start, ...): a [StatusBanner] in a bordered white panel on the exam
/// canvas, with [children] (details, then actions) stacked full-width below
/// it.
class StatusScreen extends StatelessWidget {
  const StatusScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
    this.children = const [],
  });

  static const double _maxWidth = 480.0;

  final IconData icon;
  final String title;
  final String message;
  final bool isError;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.border),
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(AppDimensions.radiusDefault),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingXl,
                  0,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatusBanner(
                      icon: icon,
                      title: title,
                      message: message,
                      isError: isError,
                    ),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
