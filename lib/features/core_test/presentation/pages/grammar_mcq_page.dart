import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../widgets/mcq_question_group.dart';

const int _defaultCurrentScreen = 1;
const int _defaultTotalScreens = 30;
const int _defaultTimeRemainingMinutes = 24;
const Duration _defaultTimeRemaining = Duration(
  minutes: _defaultTimeRemainingMinutes,
);

/// The example row is pre-answered and fixed on its correct option.
const int _exampleSelectedIndex = 0;

class GrammarMcqPage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const GrammarMcqPage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  State<GrammarMcqPage> createState() => _GrammarMcqPageState();
}

class _GrammarMcqPageState extends State<GrammarMcqPage> {
  // TODO(sample-data): replace with data from ExamAttemptInProgress once a
  // Question entity + `questions` field exist on the state (currently absent;
  // see exam_attempt_state.dart). Wiring to ExamAttemptBloc is deferred until
  // then; dispatching AnswerQuestion now would flush mock content to the
  // real backend.
  int? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: widget.currentScreen,
      totalScreens: widget.totalScreens,
      timeRemaining: widget.timeRemaining,
      // First screen of the part has no Back action.
      showBack: false,
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
        const McqQuestionGroup(
          exampleLabel: AppStrings.grammarExampleLabel,
          prompt: AppStrings.grammarExamplePrompt,
          options: AppStrings.grammarExampleOptions,
          selectedIndex: _exampleSelectedIndex,
        ),
        const SizedBox(height: AppDimensions.mcqGroupGap),
        McqQuestionGroup(
          prompt: AppStrings.grammarQuestionPrompt,
          options: AppStrings.grammarQuestionOptions,
          selectedIndex: _selectedAnswer,
          onSelected: (index) {
            setState(() {
              _selectedAnswer = index;
            });
          },
        ),
      ],
    );
  }
}
