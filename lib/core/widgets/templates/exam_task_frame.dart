import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

/// Common visual frame for every candidate task.
///
/// The exam shell owns the persistent header and footer. This widget owns the
/// shared body treatment shown by the reference PTE screens: a light canvas,
/// a centered white task surface, the task-type heading and the emphasized
/// instruction. Task-specific controls are supplied through [body].
class ExamTaskFrame extends StatelessWidget {
  const ExamTaskFrame({
    super.key,
    required this.title,
    required this.instruction,
    required this.body,
    this.maxWidth = double.infinity,
    this.contentMaxWidth = double.infinity,
  });

  final String title;
  final String instruction;
  final Widget body;
  final double maxWidth;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceCanvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final outerHorizontalPadding = compact
              ? AppDimensions.spacingMd
              : AppDimensions.spacingLg;
          final outerVerticalPadding = compact
              ? AppDimensions.spacingMd
              : AppDimensions.spacingLg;
          final cardPadding = compact
              ? AppDimensions.spacingMd
              : AppDimensions.spacingXl;
          final minCardHeight = constraints.hasBoundedHeight
              ? (constraints.maxHeight -
                        outerVerticalPadding * 2 -
                        40 -
                        AppDimensions.spacingMd)
                    .clamp(0.0, double.infinity)
              : 0.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: outerHorizontalPadding,
              vertical: outerVerticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: AppTypography.examSectionTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Container(
                      key: const ValueKey('examTaskFrame'),
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: minCardHeight),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.examBodyRadius,
                        ),
                      ),
                      padding: EdgeInsets.all(cardPadding),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: DefaultTextStyle.merge(
                            style: AppTypography.bodyPassage.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (instruction.isNotEmpty)
                                  Text(
                                    instruction,
                                    style: AppTypography.instructionBold
                                        .copyWith(
                                          color: AppColors.textPrimary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                if (instruction.isNotEmpty)
                                  const SizedBox(
                                    height: AppDimensions.spacingLg,
                                  ),
                                body,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
