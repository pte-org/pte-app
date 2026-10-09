import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_theme.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ExamUiPreviewScreen(),
    ),
  );
}
