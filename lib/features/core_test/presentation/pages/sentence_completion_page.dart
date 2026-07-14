import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../widgets/sentence_completion_list.dart';

const int _defaultCurrentScreen = 28;
const int _defaultTotalScreens = 30;
const int _defaultTimeRemainingMinutes = 23;
const Duration _defaultTimeRemaining = Duration(
  minutes: _defaultTimeRemainingMinutes,
);

class SentenceCompletionPage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const SentenceCompletionPage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  State<SentenceCompletionPage> createState() => _SentenceCompletionPageState();
}

class _SentenceCompletionPageState extends State<SentenceCompletionPage> {
  // TODO(sample-data): replace with data from ExamAttemptInProgress once a
  // Question entity + `questions` field exist on the state (currently absent;
  // see exam_attempt_state.dart). Wiring to ExamAttemptBloc is deferred until
  // then; dispatching AnswerQuestion now would flush mock content to the
  // real backend.
  late final Map<int, String?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = {
      for (int i = 0; i < AppStrings.sentenceCompletionPre.length; i++) i: null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: widget.currentScreen,
      totalScreens: widget.totalScreens,
      timeRemaining: widget.timeRemaining,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
      // TODO(exam-flow): dispatch FinishPartEvent / SubmitExamEvent when wired.
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
          AppStrings.sentenceCompletionInstruction,
          style: AppTextStyles.instructionBold,
        ),
        const SizedBox(height: AppDimensions.sentenceInstructionGap),
        SentenceCompletionList(
          preTexts: AppStrings.sentenceCompletionPre,
          postTexts: AppStrings.sentenceCompletionPost,
          wordBank: AppStrings.sentenceCompletionWordBank,
          answers: _answers,
          onAnswerChanged: (index, value) {
            setState(() {
              _answers[index] = value;
            });
          },
        ),
      ],
    );
  }
}
