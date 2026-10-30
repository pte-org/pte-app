import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/listening_choice_prompt.dart';

void main() {
  test('retains final question and discards multi-paragraph transcript', () {
    expect(
      listeningChoiceQuestion(
        'Transcript one.\n\nTranscript two.\n\nThe purpose of this talk is to ____',
      ),
      'The purpose of this talk is to ____',
    );
  });
  test('supports question-only and Windows line endings', () {
    expect(
      listeningChoiceQuestion('What does the speaker suggest?'),
      'What does the speaker suggest?',
    );
    expect(
      listeningChoiceQuestion(
        'Transcript.\r\n\r\nWhich qualities are mentioned',
      ),
      'Which qualities are mentioned',
    );
  });
  test('does not expose transcript-only or empty prompts', () {
    expect(
      listeningChoiceQuestion('Today we are going to discuss architecture.'),
      '',
    );
    expect(listeningChoiceQuestion(null), '');
  });
}
