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
  static const double readAloudRecorderMaxWidth = 660.0;
  static const double audioPanelMaxWidth = 660.0;
  static const double statusAudioPanelMaxWidth = 410.0;
  static const double statusSpeakingContentMaxWidth = 1200.0;
  static const double situationPassageMaxWidth = 1080.0;
  static const double editorToolbarCounterBreakpoint = 450.0;
  static const double inlineBlankMinWidth = 96.0;
  static const double inlineBlankMaxWidth = 240.0;
  static const double inlineBlankControlSpace = 44.0;
  static const double inlineBlankRadius = 6.0;
  static const double inlineBlankControlHeight = 32.0;
  static const double inlineBlankMenuMaxHeight = 280.0;
  static const double inlineBlankArrowSize = 18.0;
  static const double statusAudioPanelMinHeight = 210.0;
  static const double statusAudioProgressHeight = 16.0;
  static const double discussionIllustrationSize = 400.0;
  static const double discussionBubbleSize = 140.0;
  static const double discussionPeopleSize = 220.0;
  static const double audioPanelMainHeight = 168.0;
  static const double audioPanelControlsHeight = 56.0;
  static const double audioPanelRailWidth = 68.0;
  static const double audioPanelControlCellWidth = 70.0;
  static const double audioPanelProgressHeight = 4.0;
  static const double audioPanelMeterWidth = 32.0;
  static const double audioPanelMeterHeight = 60.0;
  static const int audioPanelMeterSegments = 12;
  static const double audioPanelMeterSegmentHeight = 3.0;
  static const double audioPanelMeterSegmentGap = 2.0;
  static const double audioPanelRadius = 3.0;
  static const double audioVolumePopupWidth = 260.0;
  static const double audioVolumeRowHeight = 48.0;
  static const double audioVolumePercentWidth = 40.0;
  static const double examBodyRadius = 8.0;
  static const double readAloudRadius = examBodyRadius;
  static const double writingEditorHeight = 240.0;
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
  static const double paragraphArrowIconSize = 40.0;
  static const double dragBlankMinWidth = 128.0;
  static const double dragBlankMaxWidth = 220.0;
  static const double dragBlankHeight = 40.0;
  static const double dragWordBankMinHeight = 88.0;
  static const double listeningBlankWidth = 200.0;
  static const double listeningBlankHeight = 40.0;
  static const double editorToolbarButtonSize = 36.0;
  static const double countdownTimerFontSize = 14.0;
  static const double passagePanelMaxHeight = 240.0;
  static const double passagePanelBorderWidth = borderWidth;
  static const double writingHeaderPaddingHorizontal = spacingMd;
  static const double writingHeaderPaddingVertical = spacingSm;
  static const double recordingProgressBarHeight = 6.0;
  static const double recordingProgressBarRadius = 0.0;
  static const double recordingWaveformHeight = 40.0;
  static const double recordingWaveformBarWidth = 3.0;
  static const double recordingWaveformBarGap = 3.0;
  static const double examBrandFontSize = 11.0;
  static const double audioListeningMeterHeight = 2.0;
  static const double audioListeningDotSize = 12.0;
  static const double taskImageDisplayHeight = 240.0;
}
