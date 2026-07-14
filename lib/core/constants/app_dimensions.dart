/// Spacing, sizing, and radii used across the Aptis app.
///
/// No widget should hardcode a meaningful numeric dimension inline —
/// name it here instead. Grouped by surface area so related values sit
/// together.
class AppDimensions {
  AppDimensions._();

  // --- Generic spacing scale -----------------------------------------
  static const double spacingXs = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 40.0;
  static const double spacingHuge = 48.0;

  // --- Resizable surfaces --------------------------------------------
  static const double resizablePaddingSides = 2.0;
  static const double resizableHandleSize = 34.0;
  static const double resizableHandleInset = 8.0;

  // --- Login ---------------------------------------------------------
  static const double loginShellMaxWidth = 1080.0;
  static const double loginShellMinHeight = 760.0;
  static const double loginShellPadding = 48.0;
  static const double loginHeaderHeight = 54.0;
  static const double loginHeaderPaddingHorizontal = 18.0;
  static const double loginHeaderIconSize = 18.0;
  static const double loginHeaderActionGap = 20.0;
  static const double loginAccentHeight = 4.0;
  static const double loginFormWidth = 360.0;
  static const double loginFormPaddingHorizontal = 28.0;
  static const double loginFormPaddingVertical = 24.0;
  static const double loginFormGap = 12.0;
  static const double loginTitleFontSize = 16.0;
  static const double loginSubtitleFontSize = 10.0;
  static const double loginLabelFontSize = 9.0;
  static const double loginInputHeight = 36.0;
  static const double loginInputContentPaddingHorizontal = 12.0;
  static const double loginInputContentPaddingVertical = 10.0;
  static const double loginButtonHeight = 42.0;
  static const double loginButtonIconSize = 14.0;
  static const double loginFooterHeight = 56.0;
  static const double loginFooterPaddingHorizontal = 18.0;
  static const double loginFooterLinkGap = 28.0;
  static const double loginSupportIconSize = 10.0;
  static const double loginSupportGap = 5.0;
  static const double loginBackgroundLineWidth = 1.0;
  static const double loginBackgroundLineHeight = 210.0;
  static const double loginBackgroundLineGap = 170.0;
  static const int loginBackgroundLineCount = 4;

  // --- Borders -------------------------------------------------------
  static const double borderWidthThin = 1.0;
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;

  // --- Vocabulary match page -----------------------------------------
  static const double examPagePaddingHorizontal = 40.0;
  static const double examPagePaddingVertical = 24.0;
  static const double vocabularyInstructionGap = 48.0;

  // --- Exam app bar --------------------------------------------------
  static const double topBarPaddingHorizontal = 16.0;
  static const double topBarPaddingVertical = 8.0;
  static const double topBarGap = 12.0;
  static const double topBarDividerHeight = 24.0;
  static const double topBarAccentHeight = 5.0;
  static const double topBarZoomIconSize = 28.0;
  static const double topBarScreenGap = 16.0;

  // Timer
  static const double timerFontSize = 22.0;
  static const double timerLetterSpacing = 1.5;
  static const double timerLabelFontSize = 9.0;
  static const double timerLabelGap = 8.0;

  // Hide/Show time toggle button
  static const double timeToggleSize = 38.0;
  static const double timeToggleFontSize = 9.0;
  static const double timeToggleLineHeight = 1.1;

  // Brand lockup & dot grids (logo dots + menu icon dots share these)
  static const double dotSize = 4.0;
  static const double dotMargin = 1.0;
  static const double brandDotGap = 6.0;
  static const double brandCouncilAptisGap = 8.0;
  static const double brandCouncilFontSize = 8.0;
  static const double brandCouncilLineHeight = 1.1;
  static const double brandAptisFontSize = 22.0;
  static const double brandAptisLineHeight = 0.9;
  static const double brandTaglineFontSize = 4.5;
  static const double brandTaglineLineHeight = 1.1;

  // Screen counter
  static const double screenCounterFontSize = 18.0;
  static const double screenCounterNumberFontSize = 20.0;

  // --- Exam bottom bar -----------------------------------------------
  static const double bottomBarHeight = 55.0;
  static const double bottomBarButtonWidth = 150.0;
  static const double bottomBarChevronSize = 24.0;
  static const double bottomBarButtonIconGapLeading = 4.0;
  static const double bottomBarButtonIconGapTrailing = 8.0;
  static const double bottomBarNavFontSize = 18.0;
  static const double flagIconSize = 20.0;
  static const double flagStrokeWidth = 2.0;

  // --- Grammar MCQ page ----------------------------------------------
  static const double mcqRadioSize = 40.0;
  static const double mcqRadioInnerSize = 18.0;
  static const double mcqRadioBorderWidth = 1.5;
  static const double mcqRadioLabelGap = 20.0;
  static const double mcqOptionRowGap = 20.0;
  static const double mcqPromptGap = 24.0;
  static const double mcqGroupGap = 40.0;
  static const double mcqPromptFontSize = 16.0;
  static const double mcqOptionFontSize = 16.0;
  static const double radioShadowBlur = 2.0;
  static const double radioShadowOffsetY = 1.0;

  // --- Sentence completion page --------------------------------------
  static const double sentenceInstructionGap = 32.0;
  static const double sentenceRowGap = 20.0;
  static const double sentenceLineHeight = 1.6;
  static const double sentenceFontSize = 16.0;
  static const double sentenceInlineDropdownWidth = 120.0;
  static const double sentenceInlineDropdownHeight = 38.0;
  static const double sentenceInlineDropdownPaddingH = 8.0;
  static const double sentenceInlineDropdownIconSize = 22.0;

  // --- Reading -------------------------------------------------------
  static const double readingMessageLineGap = 14.0;
  static const double readingMessageBlockGap = 20.0;
  static const double readingTitleFontSize = 18.0;
  static const double readingPassageTitleGap = 12.0;
  static const double readingPassageParagraphGap = 12.0;
  static const double headingRowGap = 14.0;
  static const double headingNumberWidth = 28.0;
  static const double headingDropdownWidth = 250.0;
  static const double headingDropdownHeight = 40.0;
  static const double readingSplitDividerWidth = 12.0;
  static const double readingSplitMinPaneWidth = 220.0;
  static const double readingSplitDefaultLeftFraction = 0.52;
  static const double readingSplitHandleWidth = 4.0;
  static const double readingTileGap = 12.0;
  static const double readingTilePaddingH = 14.0;
  static const double readingTilePaddingV = 12.0;
  static const double readingTileRadius = 4.0;
  static const double readingGapSlotWidth = 112.0;
  static const double readingGapSlotHeight = 30.0;

  // --- Word matching grid --------------------------------------------
  static const double matchWordWidth = 150.0;
  static const double matchWordWideWidth = 360.0;
  static const double matchWordGap = 2.0;
  static const double matchWordFontSize = 16.0;
  static const double matchDropdownWidth = 130.0;
  static const double matchDropdownHeight = 38.0;
  static const double matchDropdownPaddingH = 8.0;
  static const double matchDropdownIconSize = 24.0;

  // --- Listening player & options ------------------------------------
  static const double audioPlayerHeight = 40.0;
  static const double audioPlayerIconSize = 24.0;
  static const double optionRadioSize = 24.0;
  // --- Speaking test -------------------------------------------------
  static const double speakingPagePadding = 32.0;
  static const double speakingCardDefaultWidth = 1120.0;
  static const double speakingCardDefaultHeight = 360.0;
  static const double speakingCardMinWidth = 640.0;
  static const double speakingCardMinHeight = 260.0;
  static const double speakingCardMaxWidth = 1500.0;
  static const double speakingCardMaxHeight = 680.0;
  static const double speakingCardShadowBlur = 12.0;
  static const double speakingCardShadowOffsetY = 5.0;
  static const double speakingHeaderHeight = 42.0;
  static const double speakingHeaderPaddingHorizontal = 22.0;
  static const double speakingHeaderAccentHeight = 5.0;
  static const double speakingBodyMinHeight = 190.0;
  static const double speakingBodyPaddingHorizontal = 96.0;
  static const double speakingBodyPaddingVertical = 36.0;
  static const double speakingBodyGap = 82.0;
  static const double speakingFooterHeight = 44.0;
  static const double speakingMicButtonSize = 104.0;
  static const double speakingMicIconSize = 48.0;
  static const double speakingMicBorderWidth = 4.0;
  static const double speakingDotSize = 9.0;
  static const double speakingDotGap = 6.0;
  static const double speakingQuestionTextWidth = 520.0;
  static const double speakingImagePromptTextWidth = 220.0;
  static const double speakingPromptImageWidth = 190.0;
  static const double speakingPromptImageHeight = 132.0;
  static const double speakingPromptImageBorderWidth = 2.0;
  static const double speakingFooterLabelFontSize = 12.0;
  static const double speakingPromptFontSize = 15.0;
  static const double speakingPromptLineHeight = 1.45;
  static const double speakingImageLabelGap = 18.0;
}
