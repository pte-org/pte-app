import 'package:flutter/material.dart';

import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Pure presentational counterpart to `WordCountLabel` — that widget
/// hardcodes `BlocSelector<WriteEssayCubit, WriteEssayState, int>`
/// internally, so it cannot render a listening cubit's word count without
/// repeating `McOptionList`'s coupling bug (phase-03 red-team finding).
/// Takes [wordCount] as a plain prop; the caller's own `BlocBuilder`
/// extracts it. Guidance-only — never blocks submission (same as
/// `WordCountLabel`).
class ListeningWordCountLabel extends StatelessWidget {
  const ListeningWordCountLabel({super.key, required this.wordCount, this.minWordCount, this.maxWordCount});

  final int wordCount;
  final int? minWordCount;
  final int? maxWordCount;

  @override
  Widget build(BuildContext context) {
    return Text('$wordCount${ExamAttemptStrings.wordCountSuffix}${_boundsLabel()}');
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
