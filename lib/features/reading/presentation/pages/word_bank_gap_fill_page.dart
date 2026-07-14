import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../widgets/word_bank_gap_fill.dart';

const int _defaultCurrentScreen = 3;
const int _defaultTotalScreens = 4;
const Duration _defaultTimeRemaining = Duration(minutes: 26);

class WordBankGapFillPage extends StatelessWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const WordBankGapFillPage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: currentScreen,
      totalScreens: totalScreens,
      timeRemaining: timeRemaining,
      onBack: onBack ?? () => Navigator.of(context).pop(),
      onFlag: onFlag ?? () {},
      onNext: onNext ?? () {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.readingWordBankInstruction,
            style: AppTextStyles.instructionBold,
          ),
          const SizedBox(height: AppDimensions.readingMessageBlockGap),
          // TODO(sample-data): replace with data from a Reading Question entity
          // once it exists; bloc/backend wiring is deferred.
          const WordBankGapFill(
            title: AppStrings.readingWordBankTitle,
            segments: AppStrings.readingWordBankSegments,
            gapCount: AppStrings.readingWordBankGapCount,
            tiles: AppStrings.readingWordBankTiles,
            fixedAnswer: AppStrings.readingWordBankFirstAnswer,
          ),
        ],
      ),
    );
  }
}
