class MultipleChoiceUIModel {
  final String text;
  final List<String> options;

  MultipleChoiceUIModel({
    required this.text,
    required this.options,
  });
}

class MatchingUIModel {
  final String instruction;
  final String subInstruction;
  final List<String> labels;
  final List<List<String>> optionsList;

  MatchingUIModel({
    required this.instruction,
    required this.subInstruction,
    required this.labels,
    required this.optionsList,
  });
}
