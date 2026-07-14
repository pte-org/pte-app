import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../widgets/word_matching_grid.dart';

const int _defaultTotalScreens = 30;
const Duration _defaultTimeRemaining = Duration(minutes: 23);

/// A generic "label on the left → dropdown on the right" match screen.
///
/// Configured via [instruction], [words] and [optionsList] so it serves the
/// synonym (Q26), definition (Q27) and collocation (Q30) questions. Defaults to
/// the Q26 synonym content when constructed with no arguments. Set
/// [leftAligned] for the wider, left-aligned, wrapping definition layout.
class WordMatchPage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final String instruction;
  final List<String> words;
  final List<List<String>> optionsList;
  final bool leftAligned;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const WordMatchPage({
    super.key,
    this.currentScreen = 26,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.instruction = AppStrings.vocabularyMatchInstruction,
    this.words = AppStrings.vocabularySampleWords,
    this.optionsList = AppStrings.vocabularySampleOptions,
    this.leftAligned = false,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  State<WordMatchPage> createState() => _WordMatchPageState();
}

class _WordMatchPageState extends State<WordMatchPage> {
  // TODO(sample-data): replace with data from ExamAttemptInProgress once a
  // Question entity + `questions` field exist on the state (currently absent;
  // see exam_attempt_state.dart). Wiring to ExamAttemptBloc is deferred.
  late final Map<int, String?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = {for (int i = 0; i < widget.words.length; i++) i: null};
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
        Text(widget.instruction, style: AppTextStyles.instructionBold),
        const SizedBox(height: AppDimensions.vocabularyInstructionGap),
        WordMatchingGrid(
          words: widget.words,
          optionsList: widget.optionsList,
          answers: _answers,
          leftAligned: widget.leftAligned,
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
