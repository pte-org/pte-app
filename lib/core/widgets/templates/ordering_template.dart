import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'exam_template_frame.dart';

class OrderingTemplate extends StatelessWidget {
  const OrderingTemplate({
    super.key,
    required this.title,
    this.subtitle,
    required this.instruction,
    required this.stimulus,
    required this.response,
    this.metadata = const [],
    this.maxWidth = AppDimensions.contentMaxWidth,
  });

  final String title;
  final String? subtitle;
  final String instruction;
  final Widget stimulus;
  final Widget response;
  final List<String> metadata;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ExamTemplateFrame(
    title: title,
    subtitle: subtitle,
    instruction: instruction,
    stimulus: stimulus,
    response: response,
    metadata: metadata,
    maxWidth: maxWidth,
  );
}
