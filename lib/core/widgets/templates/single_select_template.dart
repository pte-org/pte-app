import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/templates/exam_template_frame.dart';

class SingleSelectTemplate extends StatelessWidget {
  const SingleSelectTemplate({
    super.key,
    required this.title,
    this.subtitle,
    required this.instruction,
    required this.stimulus,
    required this.response,
    this.reference,
    this.metadata = const [],
    this.readingLayout = false,
  });

  final String title;
  final String? subtitle;
  final String instruction;
  final Widget stimulus;
  final Widget response;
  final String? reference;
  final List<String> metadata;
  final bool readingLayout;

  @override
  Widget build(BuildContext context) {
    return ExamTemplateFrame(
      title: title,
      subtitle: subtitle,
      instruction: instruction,
      stimulus: stimulus,
      response: response,
      reference: reference,
      metadata: metadata,
      maxWidth: readingLayout
          ? AppDimensions.readingWorkstationMaxWidth
          : AppDimensions.contentMaxWidth,
    );
  }
}
