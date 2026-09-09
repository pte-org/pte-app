import 'package:flutter/material.dart';

/// Color palette. No `Color(0xFF...)` outside this file per
/// `docs/CODING_STANDARDS_APP.md`.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color error = Color(0xFFF44336);
  static const Color warningBackground = Color(0xFFFFF8E1);
  static const Color warningForeground = Color(0xFF8D6E00);
  static const Color warningIcon = Color(0xFFFFB300);
  static const Color textPrimary = Color(0xFF212121);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color examBottomBarNeutral = Color(0xFFEEEEEE);

  static const Color examHeaderGradientStart = Color(0xFF1E88E5);
  static const Color examHeaderGradientEnd = Color(0xFF1565C0);
  static const Color fillBlanksGapEmptyBorder = Color(0xFF9E9E9E);
  static const Color fillBlanksGapFilledBackground = Color(0xFFE3F2FD);
  static const Color dragChipBackground = Color(0xFFECEFF1);
  static const Color dragTargetHoverBackground = Color(0xFFBBDEFB);

  static const Color readingPageBackground = Color(0xFFF2F4F7);
  static const Color readingContentCardBorder = Color(0xFFE0E0E0);
  static const Color readingContentCardShadow = Color(0x14000000);
  static const Color taskAdvanceWarningIcon = Color(0xFFFFB300);

  static const Color textSecondary = Color(0xFF757575);
  static const Color statusBannerIconBackground = Color(0xFFE3F2FD);
  static const Color statusBannerErrorIconBackground = Color(0xFFFFEBEE);

  // Writing task surfaces.
  static const Color passagePanelBorder = Color(0xFFE0E0E0);
  static const Color passagePanelBackground = Color(0xFFF5F5F5);
  static const Color editorToolbarBackground = Color(0xFFEEEEEE);
  static const Color countdownTextColor = Color(0xFF212121);

  // Listening task surfaces — word-selection highlight states.
  static const Color wordSelectedBackground = Color(0xFFFFCDD2);
  static const Color wordUnselectedBackground = Color(0x00000000);
}
