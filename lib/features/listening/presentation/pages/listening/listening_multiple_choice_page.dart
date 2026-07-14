import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../../widgets/listening/audio_player_bar.dart';
import '../../widgets/listening/multiple_choice_option.dart';

import 'package:aptis_app/features/listening/data/models/question.dart';
import 'package:aptis_app/features/listening/domain/mappers/listening_question_mapper.dart';
import 'package:aptis_app/features/listening/presentation/models/listening_ui_models.dart';
import 'package:aptis_app/features/listening/presentation/models/listening_answer.dart';

const int _defaultCurrentScreen = 12;
const int _defaultTotalScreens = 25;
const int _defaultTimeRemainingMinutes = 53;
const Duration _defaultTimeRemaining = Duration(
  minutes: _defaultTimeRemainingMinutes,
);

class ListeningMultipleChoicePage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final Question? questionData;
  final MultipleChoiceAnswer? initialAnswer;
  final ValueChanged<MultipleChoiceAnswer>? onAnswerChanged;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const ListeningMultipleChoicePage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.questionData,
    this.initialAnswer,
    this.onAnswerChanged,
    this.onNext,
    this.onBack,
  });

  @override
  State<ListeningMultipleChoicePage> createState() =>
      _ListeningMultipleChoicePageState();
}

class _ListeningMultipleChoicePageState
    extends State<ListeningMultipleChoicePage> {
  // Local state for the selected option index per question
  late List<int?> _selectedIndices;
  late List<MultipleChoiceUIModel> _questions;

  final List<String> _labels = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    // Use mapper to convert Question data to UI models
    if (widget.questionData != null) {
      _questions = ListeningQuestionMapper.mapToMultipleChoice(widget.questionData!);
    } else {
      _questions = [];
    }
    
    if (widget.initialAnswer != null) {
      _selectedIndices = List.from(widget.initialAnswer!.selectedIndices);
    } else {
      _selectedIndices = List.filled(_questions.length, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: widget.currentScreen,
      totalScreens: widget.totalScreens,
      timeRemaining: widget.timeRemaining,
      scrollableBody: false,
      // Remove contentPadding so AudioPlayerBar spans the entire width
      contentPadding: EdgeInsets.zero,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
      onFlag: () {},
      onNext: widget.onNext ?? () {},
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AudioPlayerBar(
          audioUrl: widget.questionData?.assetCdnUrl,
          maxPlayCount: widget.questionData?.maxPlayCount ?? 2,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.examPagePaddingHorizontal,
              vertical: AppDimensions.examPagePaddingVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_questions.length, (qIndex) {
                final question = _questions[qIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingLarge * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: AppTextStyles.instruction,
                      ),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      ...List.generate(
                        question.options.length,
                        (optIndex) => MultipleChoiceOption(
                          label: _labels[optIndex],
                          text: question.options[optIndex],
                          isSelected: _selectedIndices[qIndex] == optIndex,
                          onTap: () {
                            setState(() {
                              _selectedIndices[qIndex] = optIndex;
                            });
                            widget.onAnswerChanged?.call(MultipleChoiceAnswer(_selectedIndices));
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
