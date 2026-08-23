import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/write_essay_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/write_essay_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Live word-count guidance only — never blocks submission or navigation,
/// never a hard error for being outside bounds (phase-05 Design
/// Constraints). `BlocSelector` limits rebuild to just
/// [WriteEssayState.wordCount] — precomputed once per `draftChanged` call
/// by `WriteEssayCubit`, not recomputed here on every selector evaluation.
class WordCountLabel extends StatelessWidget {
  const WordCountLabel({super.key, this.minWordCount, this.maxWordCount});

  final int? minWordCount;
  final int? maxWordCount;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WriteEssayCubit, WriteEssayState, int>(
      selector: (state) => state.wordCount,
      builder: (context, wordCount) {
        return Text('$wordCount${ExamAttemptStrings.wordCountSuffix}${_boundsLabel()}');
      },
    );
  }

  String _boundsLabel() {
    final parts = [
      if (minWordCount != null) '${ExamAttemptStrings.wordCountMinLabel}$minWordCount',
      if (maxWordCount != null) '${ExamAttemptStrings.wordCountMaxLabel}$maxWordCount',
    ];
    if (parts.isEmpty) return '';
    return '${ExamAttemptStrings.wordCountBoundsOpen}${parts.join(ExamAttemptStrings.wordCountBoundsSeparator)}${ExamAttemptStrings.wordCountBoundsClose}';
  }
}
