import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../widgets/heading_match_body.dart';

const int _defaultCurrentScreen = 4;
const int _defaultTotalScreens = 4;
const Duration _defaultTimeRemaining = Duration(minutes: 24);
const int _paragraphCount = 7;

class HeadingMatchPage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const HeadingMatchPage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  State<HeadingMatchPage> createState() => _HeadingMatchPageState();
}

class _HeadingMatchPageState extends State<HeadingMatchPage> {
  // TODO(sample-data): replace with data from a Reading Question entity once it
  // exists; wiring to a bloc/backend is deferred.
  late final Map<int, String?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = {for (int i = 0; i < _paragraphCount; i++) i: null};
  }

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: widget.currentScreen,
      totalScreens: widget.totalScreens,
      timeRemaining: widget.timeRemaining,
      // The left passage scrolls internally, so the frame must not scroll.
      scrollableBody: false,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
      onFlag: widget.onFlag ?? () {},
      onNext: widget.onNext ?? () {},
      body: HeadingMatchBody(
        instruction: AppStrings.readingHeadingInstruction,
        passageTitle: AppStrings.readingPassageTitle,
        paragraphs: AppStrings.readingPassageParagraphs,
        headingOptions: AppStrings.readingHeadingOptions,
        answers: _answers,
        onAnswerChanged: (index, value) {
          setState(() => _answers[index] = value);
        },
      ),
    );
  }
}
