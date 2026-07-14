import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import '../../widgets/listening/audio_player_bar.dart';
import '../../widgets/listening/dropdown_matching_list.dart';

import 'package:aptis_app/features/listening/data/models/question.dart';
import 'package:aptis_app/features/listening/domain/mappers/listening_question_mapper.dart';
import 'package:aptis_app/features/listening/presentation/models/listening_ui_models.dart';
import 'package:aptis_app/features/listening/presentation/models/listening_answer.dart';

const int _defaultCurrentScreen = 13;
const int _defaultTotalScreens = 25;
const int _defaultTimeRemainingMinutes = 53;
const Duration _defaultTimeRemaining = Duration(
  minutes: _defaultTimeRemainingMinutes,
);

class ListeningMatchingPage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final Question? questionData;
  final MatchingAnswer? initialAnswer;
  final ValueChanged<MatchingAnswer>? onAnswerChanged;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const ListeningMatchingPage({
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
  State<ListeningMatchingPage> createState() => _ListeningMatchingPageState();
}

class _ListeningMatchingPageState extends State<ListeningMatchingPage> {
  late List<String?> _selectedValues;
  late MatchingUIModel _data;

  @override
  void initState() {
    super.initState();
    if (widget.questionData != null) {
      _data = ListeningQuestionMapper.mapToMatching(widget.questionData!);
    } else {
      _data = MatchingUIModel(
        instruction: "No data",
        subInstruction: "",
        labels: [],
        optionsList: [],
      );
    }

    if (widget.initialAnswer != null) {
      _selectedValues = List.from(widget.initialAnswer!.selectedValues);
    } else {
      _selectedValues = List.filled(_data.labels.length, null);
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
              children: [
                Text(
                  _data.instruction,
                  style: AppTextStyles.instruction,
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                Text(
                  _data.subInstruction,
                  style: AppTextStyles.instruction.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                DropdownMatchingList(
                  labels: _data.labels,
                  optionsList: _data.optionsList,
                  selectedValues: _selectedValues,
                  onChanged: (index, value) {
                    setState(() {
                      _selectedValues[index] = value;
                    });
                    widget.onAnswerChanged?.call(MatchingAnswer(_selectedValues));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
