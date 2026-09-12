/// Source-backed spacing, geometry and component dimensions for the exam UI.
class AppDimensions {
  const AppDimensions._();

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const double radiusSm = 2.0;
  static const double radiusDefault = 3.0;
  static const double radiusMd = 3.0;
  static const double radiusLg = 3.0;
  static const double radiusFull = 9999.0;

  static const double contentMaxWidth = 960.0;
  static const double readingWorkstationMaxWidth = 1160.0;
  static const double examHeaderHeight = 56.0;
  static const double examFooterHeight = 56.0;
  static const double examHeaderCompactBreakpoint = 1080.0;
  static const double templateSideBySideBreakpoint = 720.0;
  static const double buttonHeight = 36.0;
  static const double borderWidth = 1.0;

  // Compatibility names retained until the final cleanup phase.
  @Deprecated('Use spacingMd')
  static const double spacingMedium = spacingMd;
  @Deprecated('Use radiusDefault')
  static const double radiusMedium = radiusDefault;
  static const double loginFormMaxWidth = 420.0;
  @Deprecated('Use examFooterHeight')
  static const double examBottomBarHeight = examFooterHeight;
  static const double advanceButtonSpinnerSize = 16.0;
  static const double advanceButtonSpinnerStrokeWidth = 2.0;
  static const double examHeaderBannerRadius = radiusDefault;
  static const double examHeaderBannerPaddingVertical = spacingSm;
  static const double examHeaderBannerPaddingHorizontal = spacingMd;
  static const double examHeaderStarIconSize = 20.0;
  static const double examHeaderTitleFontSize = 14.0;
  static const double examHeaderInstructionSpacing = spacingXs;
  static const double examHeaderInstructionFontSize = 13.0;
  static const double devPreviewBackButtonOffset = spacingSm;
  static const double fillBlanksGapMinWidth = 72.0;
  static const double fillBlanksGapPadding = 6.0;
  static const double dragChipPadding = spacingSm;
  static const double dragChipSpacing = spacingSm;
  static const double readingContentCardMargin = spacingMd;
  static const double readingContentCardRadius = radiusDefault;
  static const double taskAdvanceWarningIconSize = 16.0;
  static const double statusBannerIconBadgeSize = 72.0;
  static const double statusBannerIconSize = 36.0;
  static const double editorToolbarIconSize = 22.0;
  static const double editorToolbarButtonSize = 36.0;
  static const double countdownTimerFontSize = 14.0;
  static const double passagePanelMaxHeight = 240.0;
  static const double passagePanelBorderWidth = borderWidth;
  static const double writingHeaderPaddingHorizontal = spacingMd;
  static const double writingHeaderPaddingVertical = spacingSm;
  static const double recordingProgressBarHeight = 6.0;
  static const double recordingProgressBarRadius = 0.0;
  static const double examBrandFontSize = 11.0;
  static const double audioListeningMeterHeight = 2.0;
  static const double audioListeningDotSize = 12.0;
  static const double taskImageDisplayHeight = 240.0;
}
