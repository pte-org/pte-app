import 'package:flutter/material.dart';

/// Semantic colors for the PTE exam UI.
///
/// `primary` and `brandPrimary` intentionally remain distinct: the design
/// bundle uses Material `primary` for the institutional role and
/// `primary-container`/brand primary for task actions.
class AppColors {
  const AppColors._();

  // Material semantic roles from DESIGN.md.
  static const Color primary = Color(0xFF004787);
  static const Color primaryContainer = Color(0xFF0B5FAE);
  static const Color brandPrimary = Color(0xFF0B5FAE);
  static const Color primaryHover = Color(0xFF094C8B);
  static const Color primaryActive = Color(0xFF073B6D);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color surfaceCanvas = Color(0xFFF7F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFEDF4FF);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F1);

  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF5A6473);
  static const Color textMuted = Color(0xFF8A94A6);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFC9CFD9);
  static const Color borderSubtle = Color(0xFFE2E7EE);
  static const Color divider = Color(0xFFD8DCE3);
  static const Color outline = Color(0xFF727783);

  static const Color error = Color(0xFFD93A3A);
  static const Color errorDark = Color(0xFFB02525);
  static const Color errorContainer = Color(0xFFFDECEC);
  static const Color warningBackground = Color(0xFFFFF6E5);
  static const Color warningForeground = Color(0xFF7A5B00);
  static const Color warningIcon = Color(0xFFE0A912);
  static const Color success = Color(0xFF2E7D4F);
  static const Color successContainer = Color(0xFFEAF5EE);
  static const Color inactive = Color(0xFFE4E7EB);

  static const Color interactiveHighlight = Color(0xFFF4F5F7);
  static const Color interactiveSelected = Color(0xFFEBF3FC);
  static const Color interactiveFocus = Color(0xFF0B5FAE);

  // Offline fixture illustration colors. They are kept in the token file so
  // preview art cannot introduce ad-hoc color literals in feature code.
  static const Color previewSky = Color(0xFF6BA9D1);
  static const Color previewSun = Color(0xFFFFD166);
  static const Color previewGround = Color(0xFF3D8060);

  // Compatibility aliases. Remove after the strangler migration is complete.
  @Deprecated('Use primaryContainer or brandPrimary')
  static const Color examHeaderGradientStart = brandPrimary;
  @Deprecated('Use primaryHover')
  static const Color examHeaderGradientEnd = primaryHover;
  @Deprecated('Use border')
  static const Color fillBlanksGapEmptyBorder = border;
  @Deprecated('Use interactiveSelected')
  static const Color fillBlanksGapFilledBackground = interactiveSelected;
  @Deprecated('Use surfaceSubtle')
  static const Color dragChipBackground = surfaceSubtle;
  @Deprecated('Use interactiveSelected')
  static const Color dragTargetHoverBackground = interactiveSelected;
  @Deprecated('Use surfaceCanvas')
  static const Color readingPageBackground = surfaceCanvas;
  @Deprecated('Use borderSubtle')
  static const Color readingContentCardBorder = borderSubtle;
  @Deprecated('Use surfaceSubtle; shadows are not used by the design')
  static const Color readingContentCardShadow = Color(0x00000000);
  @Deprecated('Use warningIcon')
  static const Color taskAdvanceWarningIcon = warningIcon;
  @Deprecated('Use interactiveSelected')
  static const Color statusBannerIconBackground = interactiveSelected;
  @Deprecated('Use errorContainer')
  static const Color statusBannerErrorIconBackground = errorContainer;
  @Deprecated('Use border')
  static const Color passagePanelBorder = border;
  @Deprecated('Use surfaceSubtle')
  static const Color passagePanelBackground = surfaceSubtle;
  @Deprecated('Use surfaceSubtle')
  static const Color editorToolbarBackground = surfaceSubtle;
  @Deprecated('Use textPrimary')
  static const Color countdownTextColor = textPrimary;
  @Deprecated('Use errorContainer')
  static const Color wordSelectedBackground = errorContainer;
  @Deprecated('Use surface')
  static const Color wordUnselectedBackground = surface;
  @Deprecated('Use surface')
  static const Color examBottomBarNeutral = surface;
}
