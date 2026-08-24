import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/authoring/domain/authoring_types.dart';

void main() {
  group('CreateReadAloudInput', () {
    test('normalizes required title and prompt', () {
      final normalized = const CreateReadAloudInput(
        title: '  Read this  ',
        promptText: '  A short passage.  ',
      ).normalized();

      expect(normalized.title, 'Read this');
      expect(normalized.promptText, 'A short passage.');
    });

    test('rejects a blank title or prompt', () {
      expect(
        () => const CreateReadAloudInput(
          title: '',
          promptText: 'Passage',
        ).normalized(),
        throwsA(isA<AuthoringValidationException>()),
      );
    });
  });

  group('CreateWriteEssayInput', () {
    test('normalizes text and keeps valid word-count bounds', () {
      final normalized = const CreateWriteEssayInput(
        title: '  Essay  ',
        promptText: '  Discuss this.  ',
        referenceAnswerText: '  Reference answer.  ',
        minWordCount: 200,
        maxWordCount: 300,
      ).normalized();

      expect(normalized.title, 'Essay');
      expect(normalized.promptText, 'Discuss this.');
      expect(normalized.referenceAnswerText, 'Reference answer.');
      expect(normalized.minWordCount, 200);
      expect(normalized.maxWordCount, 300);
    });

    test('rejects blank reference answer', () {
      expect(
        () => const CreateWriteEssayInput(
          title: 'Essay',
          promptText: 'Prompt',
          referenceAnswerText: ' ',
          minWordCount: 200,
          maxWordCount: 300,
        ).normalized(),
        throwsA(isA<AuthoringValidationException>()),
      );
    });

    test('rejects non-positive or reversed word-count bounds', () {
      expect(
        () => const CreateWriteEssayInput(
          title: 'Essay',
          promptText: 'Prompt',
          referenceAnswerText: 'Reference',
          minWordCount: 0,
          maxWordCount: 300,
        ).normalized(),
        throwsA(isA<AuthoringValidationException>()),
      );
      expect(
        () => const CreateWriteEssayInput(
          title: 'Essay',
          promptText: 'Prompt',
          referenceAnswerText: 'Reference',
          minWordCount: 301,
          maxWordCount: 300,
        ).normalized(),
        throwsA(isA<AuthoringValidationException>()),
      );
    });
  });
}
