import 'package:flutter/material.dart';

import 'exam_template_frame.dart';

class FreeTextTemplate extends StatelessWidget {
  const FreeTextTemplate({
    super.key,
    required this.title,
    this.subtitle,
    required this.instruction,
    required this.stimulus,
    required this.response,
    this.metadata = const [],
  });

  final String title;
  final String? subtitle;
  final String instruction;
  final Widget stimulus;
  final Widget response;
  final List<String> metadata;

  @override
  Widget build(BuildContext context) => ExamTemplateFrame(
    title: title,
    subtitle: subtitle,
    instruction: instruction,
    stimulus: stimulus,
    response: response,
    metadata: metadata,
    layout: ExamTemplateLayout.stacked,
  );
}
