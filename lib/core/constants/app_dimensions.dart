/// Spacing, radius, and font-size constants. No magic numbers in widget
/// code per `docs/CODING_STANDARDS_APP.md`.
class AppDimensions {
  const AppDimensions._();

  static const double spacingMedium = 16.0;
  static const double radiusMedium = 8.0;
  static const double examBottomBarHeight = 64.0;
  static const double advanceButtonSpinnerSize = 16.0;
  static const double advanceButtonSpinnerStrokeWidth = 2.0;

  static const double examHeaderBannerRadius = 12.0;
  static const double examHeaderBannerPaddingVertical = 12.0;
  static const double examHeaderBannerPaddingHorizontal = 16.0;
  static const double examHeaderStarIconSize = 20.0;
  static const double examHeaderTitleFontSize = 16.0;
  static const double devPreviewBackButtonOffset = 8.0;
  static const double readingPassageLayoutBreakpoint = 720.0;
  static const double fillBlanksGapMinWidth = 72.0;
  static const double fillBlanksGapPadding = 6.0;
  static const double dragChipPadding = 8.0;
  static const double dragChipSpacing = 8.0;

  static const double recordingProgressBarHeight = 8.0;
  static const double recordingProgressBarRadius = 4.0;

  static const double examBrandFontSize = 11.0;

  static const double audioListeningMeterHeight = 2.0;
  static const double audioListeningDotSize = 12.0;

  /// Bounded height `TaskImageDisplay` renders inside — required for
  /// `Image.network`'s `loadingBuilder` (`CircularProgressIndicator`) to
  /// lay out correctly before the real image's intrinsic size is known.
  static const double taskImageDisplayHeight = 240.0;
}
