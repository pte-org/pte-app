import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/components/instruction_card.dart';
import 'package:pte_app/core/widgets/components/subheader_banner.dart';

enum ExamTemplateLayout { split, stacked, centeredResponse }

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
    this.maxWidth = AppDimensions.contentMaxWidth,
    this.layout = ExamTemplateLayout.split,
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
  final ExamTemplateLayout layout;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceCanvas,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubheaderBanner(
                  title: title,
                  subtitle: subtitle,
                  reference: reference,
                  skills: skills,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                InstructionCard(instruction: instruction, metadata: metadata),
                const SizedBox(height: AppDimensions.spacingMd),
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final sideBySide =
                            constraints.maxWidth >=
                            AppDimensions.templateSideBySideBreakpoint;
                        final children = [
                          _Panel(child: stimulus),
                          _Panel(child: response),
                        ];
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
                                    maxWidth: 580,
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
                                  const SizedBox(
                                    width: AppDimensions.spacingMd,
                                  ),
                                  Expanded(child: children[1]),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  children[0],
                                  const SizedBox(
                                    height: AppDimensions.spacingMd,
                                  ),
                                  children[1],
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusDefault),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: AppTypography.bodyRegular.copyWith(color: AppColors.textPrimary),
        child: child,
      ),
    );
  }
}
