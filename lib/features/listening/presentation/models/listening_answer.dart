sealed class Answer {}

class MultipleChoiceAnswer extends Answer {
  final List<int?> selectedIndices;
  MultipleChoiceAnswer(this.selectedIndices);
}

class MatchingAnswer extends Answer {
  final List<String?> selectedValues;
  MatchingAnswer(this.selectedValues);
}
