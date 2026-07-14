import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTextStyles {
  AppTextStyles._();

  // Top bar
  static const TextStyle timerValue = TextStyle(
    fontSize: AppDimensions.timerFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: AppDimensions.timerLetterSpacing,
  );

  static const TextStyle timerLabel = TextStyle(
    fontSize: AppDimensions.timerLabelFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  /// Circular toggle button ("Hide time" / "Show time").
  static const TextStyle timeToggle = TextStyle(
    fontSize: AppDimensions.timeToggleFontSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    height: AppDimensions.timeToggleLineHeight,
  );

  // Brand lockup (British Council / Aptis)
  static const TextStyle brandCouncil = TextStyle(
    fontSize: AppDimensions.brandCouncilFontSize,
    fontWeight: FontWeight.w800,
    color: AppColors.logoGray,
    height: AppDimensions.brandCouncilLineHeight,
  );

  static const TextStyle brandAptis = TextStyle(
    fontSize: AppDimensions.brandAptisFontSize,
    fontWeight: FontWeight.bold,
    color: AppColors.accentRed,
    height: AppDimensions.brandAptisLineHeight,
  );

  static const TextStyle brandAptisTagline = TextStyle(
    fontSize: AppDimensions.brandTaglineFontSize,
    color: AppColors.accentRed,
    height: AppDimensions.brandTaglineLineHeight,
  );

  /// "Screen" and " of " labels in the screen counter.
  static const TextStyle screenCounterLabel = TextStyle(
    fontSize: AppDimensions.screenCounterFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  /// Bold number spans ("26", "30") in the screen counter.
  static const TextStyle screenCounterNumber = TextStyle(
    fontSize: AppDimensions.screenCounterNumberFontSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // Content
  static const TextStyle instruction = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  /// Bold instruction variant (used by vocabulary matching).
  static const TextStyle instructionBold = TextStyle(
    fontSize: AppDimensions.matchWordFontSize,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle questionWord = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle exampleLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle exampleWord = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.exampleWord,
  );

  static const TextStyle dropdownText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  // Grammar MCQ
  static const TextStyle mcqPrompt = TextStyle(
    fontSize: AppDimensions.mcqPromptFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle mcqExampleLabel = TextStyle(
    fontSize: AppDimensions.mcqPromptFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const TextStyle mcqOptionLabel = TextStyle(
    fontSize: AppDimensions.mcqOptionFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  // Sentence completion
  static const TextStyle sentenceText = TextStyle(
    fontSize: AppDimensions.sentenceFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: AppDimensions.sentenceLineHeight,
  );

  // Reading
  static const TextStyle readingTitle = TextStyle(
    fontSize: AppDimensions.readingTitleFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  // Bottom bar
  static const TextStyle navButton = TextStyle(
    fontSize: AppDimensions.bottomBarNavFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle flagLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.flagText,
  );

  // Login
  static const TextStyle loginTitle = TextStyle(
    fontSize: AppDimensions.loginTitleFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle loginSubtitle = TextStyle(
    fontSize: AppDimensions.loginSubtitleFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  static const TextStyle loginLabel = TextStyle(
    fontSize: AppDimensions.loginLabelFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle loginInput = TextStyle(
    fontSize: AppDimensions.loginSubtitleFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const TextStyle loginButton = TextStyle(
    fontSize: AppDimensions.loginSubtitleFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle loginFooter = TextStyle(
    fontSize: AppDimensions.loginLabelFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // Speaking
  static const TextStyle speakingPrompt = TextStyle(
    fontSize: AppDimensions.speakingPromptFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: AppDimensions.speakingPromptLineHeight,
  );

  static const TextStyle speakingPromptEmphasis = TextStyle(
    fontSize: AppDimensions.speakingPromptFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: AppDimensions.speakingPromptLineHeight,
  );

  static const TextStyle speakingFooterLabel = TextStyle(
    fontSize: AppDimensions.speakingFooterLabelFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
}
