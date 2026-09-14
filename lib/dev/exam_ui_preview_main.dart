import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
      ),
      home: const ExamUiPreviewScreen(),
    ),
  );
}
