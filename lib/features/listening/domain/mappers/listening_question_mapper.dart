import '../../data/models/question.dart';
import '../../presentation/models/listening_ui_models.dart';

class ListeningQuestionMapper {
  static List<MultipleChoiceUIModel> mapToMultipleChoice(Question q) {
    // If the content has newlines, assume they are multiple sub-questions.
    final lines = q.content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    // Evenly distribute options among the parsed questions
    final optionsPerQuestion = q.options.length ~/ lines.length;

    return List.generate(lines.length, (index) {
      final startIndex = index * optionsPerQuestion;
      final endIndex = startIndex + optionsPerQuestion;
      return MultipleChoiceUIModel(
        text: lines[index],
        options: q.options.sublist(startIndex, endIndex),
      );
    });
  }

  static MatchingUIModel mapToMatching(Question q) {
    final RegExp blankRegex = RegExp(r'\[Blank\s*\d+\]');
    final matches = blankRegex.allMatches(q.content).toList();

    if (matches.isEmpty) {
      return MatchingUIModel(
        instruction: q.content,
        subInstruction: "",
        labels: [],
        optionsList: [],
      );
    }

    final lines = q.content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String instruction = "";
    String subInstruction = "";
    List<String> labels = [];

    for (final line in lines) {
      if (blankRegex.hasMatch(line)) {
        // Extract label (everything before [Blank X])
        final label = line.replaceAll(blankRegex, '').trim();
        labels.add(label);
      } else {
        // Assign non-blank lines to instruction and subInstruction
        if (instruction.isEmpty) {
          instruction = line;
        } else if (subInstruction.isEmpty) {
          subInstruction = line;
        } else {
          subInstruction += '\n$line';
        }
      }
    }

    final optionsPerDropdown =
        labels.isEmpty ? 0 : q.options.length ~/ labels.length;
    List<List<String>> optionsList = [];

    for (int i = 0; i < labels.length; i++) {
      final startIndex = i * optionsPerDropdown;
      final endIndex = startIndex + optionsPerDropdown;
      // Safety check just in case backend options array is shorter than expected
      if (endIndex <= q.options.length) {
        optionsList.add(q.options.sublist(startIndex, endIndex));
      } else {
        optionsList.add([]);
      }
    }

    return MatchingUIModel(
      instruction: instruction,
      subInstruction: subInstruction,
      labels: labels,
      optionsList: optionsList,
    );
  }
}
