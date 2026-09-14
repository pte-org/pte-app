import 'package:flutter/material.dart';

import 'exam_template_frame.dart';

class RecordResponseTemplate extends StatelessWidget {
  const RecordResponseTemplate({
    super.key,
    required this.title,
    this.subtitle,
    required this.instruction,
    required this.stimulus,
    required this.response,
    this.metadata = const [],
    this.layout = ExamTemplateLayout.split,
  });

  final String title;
  final String? subtitle;
  final String instruction;
  final Widget stimulus;
  final Widget response;
  final List<String> metadata;
  final ExamTemplateLayout layout;

  @override
  Widget build(BuildContext context) => ExamTemplateFrame(
    title: title,
    subtitle: subtitle,
    instruction: instruction,
    stimulus: stimulus,
    response: response,
    metadata: metadata,
    layout: layout,
  );
}
