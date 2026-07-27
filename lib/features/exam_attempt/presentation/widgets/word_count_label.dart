import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/word_count.dart';
import '../cubit/write_essay_cubit.dart';
import '../cubit/write_essay_state.dart';

/// Live word-count guidance only — never blocks submission or navigation,
/// never a hard error for being outside bounds (phase-05 Design
/// Constraints). `BlocSelector` limits rebuild to just the word-count
/// value derived from [WriteEssayState.draftText], not the whole draft
/// state.
class WordCountLabel extends StatelessWidget {
  const WordCountLabel({super.key, this.minWordCount, this.maxWordCount});

  final int? minWordCount;
  final int? maxWordCount;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WriteEssayCubit, WriteEssayState, int>(
      selector: (state) => countWords(state.draftText),
      builder: (context, wordCount) {
        return Text('$wordCount${AppStrings.wordCountSuffix}${_boundsLabel()}');
      },
    );
  }

  String _boundsLabel() {
    final parts = [
      if (minWordCount != null) '${AppStrings.wordCountMinLabel}$minWordCount',
      if (maxWordCount != null) '${AppStrings.wordCountMaxLabel}$maxWordCount',
    ];
    if (parts.isEmpty) return '';
    return '${AppStrings.wordCountBoundsOpen}${parts.join(AppStrings.wordCountBoundsSeparator)}${AppStrings.wordCountBoundsClose}';
  }
}
