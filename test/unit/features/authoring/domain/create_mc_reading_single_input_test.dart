import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/authoring/domain/authoring_types.dart';

void main() {
  QuestionOptionInput option(String text, int index, {bool correct = false}) {
    return QuestionOptionInput(text: text, correct: correct, orderIndex: index);
  }

  test(
    'normalized trims text and preserves a valid single-correct option set',
    () {
      final input = CreateMcReadingSingleInput(
        title: '  Reading question  ',
        promptText: '  Choose the answer.  ',
        options: [option('  Alpha  ', 0, correct: true), option(' Beta ', 1)],
      ).normalized();

      expect(input.title, 'Reading question');
      expect(input.promptText, 'Choose the answer.');
      expect(input.options.map((item) => item.text), ['Alpha', 'Beta']);
    },
  );

  for (final invalidInput in <CreateMcReadingSingleInput>[
    CreateMcReadingSingleInput(
      title: ' ',
      promptText: 'Prompt',
      options: [option('A', 0, correct: true), option('B', 1)],
    ),
    CreateMcReadingSingleInput(
      title: 'Title',
      promptText: ' ',
      options: [option('A', 0, correct: true), option('B', 1)],
    ),
    CreateMcReadingSingleInput(
      title: 'Title',
      promptText: 'Prompt',
      options: [option('A', 0, correct: true)],
    ),
    CreateMcReadingSingleInput(
      title: 'Title',
      promptText: 'Prompt',
      options: [option('A', 0), option('B', 1)],
    ),
    CreateMcReadingSingleInput(
      title: 'Title',
      promptText: 'Prompt',
      options: [option('A', 0, correct: true), option('B', 1, correct: true)],
    ),
    CreateMcReadingSingleInput(
      title: 'Title',
      promptText: 'Prompt',
      options: [option('A', 0, correct: true), option('B', 2)],
    ),
    CreateMcReadingSingleInput(
      title: 'Title',
      promptText: 'Prompt',
      options: [option('A', 0, correct: true), option(' ', 1)],
    ),
  ]) {
    test('invalid MC input is rejected before delegation', () {
      expect(
        invalidInput.normalized,
        throwsA(isA<AuthoringValidationException>()),
      );
    });
  }
}
