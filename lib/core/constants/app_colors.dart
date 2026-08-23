import 'package:flutter/material.dart';

/// Color palette. No `Color(0xFF...)` outside this file per
/// `docs/CODING_STANDARDS_APP.md`.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color error = Color(0xFFF44336);
  static const Color textPrimary = Color(0xFF212121);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color examBottomBarPrep = Color(0xFFFFA000);
  static const Color examBottomBarResponse = Color(0xFF424242);

  static const Color readingHeaderGradientStart = Color(0xFF1E88E5);
  static const Color readingHeaderGradientEnd = Color(0xFF1565C0);
  static const Color fillBlanksGapEmptyBorder = Color(0xFF9E9E9E);
  static const Color fillBlanksGapFilledBackground = Color(0xFFE3F2FD);
  static const Color dragChipBackground = Color(0xFFECEFF1);
  static const Color dragTargetHoverBackground = Color(0xFFBBDEFB);

  // Writing task surfaces.
  static const Color passagePanelBorder = Color(0xFFE0E0E0);
  static const Color passagePanelBackground = Color(0xFFF5F5F5);
  static const Color editorToolbarBackground = Color(0xFFEEEEEE);
  static const Color countdownTextColor = Color(0xFF212121);
}
