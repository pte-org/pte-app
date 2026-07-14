import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../widgets/gap_fill_message_list.dart';

const int _defaultCurrentScreen = 1;
const int _defaultTotalScreens = 4;
const Duration _defaultTimeRemaining = Duration(minutes: 34);
const int _fixedLineIndex = 0;

class GapFillMessagePage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const GapFillMessagePage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  State<GapFillMessagePage> createState() => _GapFillMessagePageState();
}

class _GapFillMessagePageState extends State<GapFillMessagePage> {
  // TODO(sample-data): replace with data from a Reading Question entity once it
  // exists; wiring to a bloc/backend is deferred.
  late final Map<int, String?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = {
      for (int i = 0; i < AppStrings.readingMessagePre.length; i++) i: null,
    };
    _answers[_fixedLineIndex] = AppStrings.readingMessageFirstAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: widget.currentScreen,
      totalScreens: widget.totalScreens,
      timeRemaining: widget.timeRemaining,
      showBack: false,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
      onFlag: widget.onFlag ?? () {},
      onNext: widget.onNext ?? () {},
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.readingGapFillInstruction,
          style: AppTextStyles.instructionBold,
        ),
        const SizedBox(height: AppDimensions.readingMessageBlockGap),
        Text(
          AppStrings.readingMessageGreeting,
          style: AppTextStyles.instructionBold,
        ),
        const SizedBox(height: AppDimensions.readingMessageBlockGap),
        GapFillMessageList(
          preTexts: AppStrings.readingMessagePre,
          postTexts: AppStrings.readingMessagePost,
          optionsList: AppStrings.readingMessageOptions,
          answers: _answers,
          fixedIndex: _fixedLineIndex,
          onAnswerChanged: (index, value) {
            setState(() => _answers[index] = value);
          },
        ),
        const SizedBox(height: AppDimensions.readingMessageBlockGap),
        Text(
          AppStrings.readingMessageSignOff,
          style: AppTextStyles.instructionBold,
        ),
        Text(
          AppStrings.readingMessageSignName,
          style: AppTextStyles.sentenceText,
        ),
      ],
    );
  }
}
