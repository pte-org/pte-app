import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'exam_task_frame.dart';

enum ExamTemplateLayout { split, stacked, centeredResponse, centeredMedia }

/// Shared composition frame for the seven task interaction families.
/// Everything task-specific is supplied as a slot; no state or domain import
/// is allowed here.
class ExamTemplateFrame extends StatelessWidget {
  const ExamTemplateFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.instruction,
    required this.stimulus,
    required this.response,
    this.reference,
    this.skills = const [],
    this.metadata = const [],
    this.maxWidth = double.infinity,
    this.contentMaxWidth = double.infinity,
    this.layout = ExamTemplateLayout.stacked,
  });

  final String title;
  final String? subtitle;
  final String instruction;
  final Widget stimulus;
  final Widget response;
  final String? reference;
  final List<String> skills;
  final List<String> metadata;
  final double maxWidth;
  final double contentMaxWidth;
  final ExamTemplateLayout layout;

  @override
  Widget build(BuildContext context) {
    return ExamTaskFrame(
      title: title,
      instruction: instruction,
      maxWidth: maxWidth,
      contentMaxWidth: contentMaxWidth,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide =
              constraints.maxWidth >=
              AppDimensions.templateSideBySideBreakpoint;
          final children = [
            _Content(child: stimulus),
            _Content(child: response),
          ];
          if (layout == ExamTemplateLayout.centeredMedia) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.readAloudRecorderMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    children[0],
                    const SizedBox(height: AppDimensions.spacingLg),
                    children[1],
                  ],
                ),
              ),
            );
          }
          if (layout == ExamTemplateLayout.stacked) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                children[0],
                const SizedBox(height: AppDimensions.spacingMd),
                children[1],
              ],
            );
          }
          if (layout == ExamTemplateLayout.centeredResponse) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                children[0],
                const SizedBox(height: AppDimensions.spacingMd),
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.readAloudRecorderMaxWidth,
                    ),
                    child: children[1],
                  ),
                ),
              ],
            );
          }
          return sideBySide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(child: children[1]),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    children[0],
                    const SizedBox(height: AppDimensions.spacingMd),
                    children[1],
                  ],
                );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DefaultTextStyle.merge(
        style: AppTypography.bodyPassage.copyWith(color: AppColors.textPrimary),
        child: child,
      ),
    );
  }
}
