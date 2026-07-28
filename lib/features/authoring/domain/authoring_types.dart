enum PteTaskType {
  mcReadingSingle('MC_READING_SINGLE'),
  readAloud('READ_ALOUD'),
  writeEssay('WRITE_ESSAY');

  const PteTaskType(this.wireName);

  final String wireName;
}

enum QuestionVisibility {
  shared('SHARED'),
  private('PRIVATE');

  const QuestionVisibility(this.wireName);

  final String wireName;
}

class QuestionOption {
  const QuestionOption({
    required this.publicId,
    required this.text,
    required this.correct,
    required this.orderIndex,
  });

  final String publicId;
  final String text;
  final bool correct;
  final int orderIndex;
}

class Question {
  Question({
    required this.publicId,
    required this.pteTaskType,
    required this.section,
    required this.visibility,
    required this.tenantId,
    required this.status,
    required this.title,
    required this.promptText,
    required this.audioPromptRef,
    required this.imagePromptRef,
    required this.referenceAnswerText,
    required this.correctAnswerText,
    required this.minWordCount,
    required this.maxWordCount,
    required List<QuestionOption> options,
    required List<String> skills,
  }) : options = List.unmodifiable(options),
       skills = List.unmodifiable(skills);

  final String publicId;
  final PteTaskType pteTaskType;
  final String section;
  final QuestionVisibility visibility;
  final String? tenantId;
  final String status;
  final String title;
  final String? promptText;
  final String? audioPromptRef;
  final String? imagePromptRef;
  final String? referenceAnswerText;
  final String? correctAnswerText;
  final int? minWordCount;
  final int? maxWordCount;
  final List<QuestionOption> options;
  final List<String> skills;
}

class QuestionOptionInput {
  const QuestionOptionInput({
    required this.text,
    required this.correct,
    required this.orderIndex,
  });

  final String text;
  final bool correct;
  final int orderIndex;

  QuestionOptionInput normalized() {
    return QuestionOptionInput(
      text: text.trim(),
      correct: correct,
      orderIndex: orderIndex,
    );
  }
}

class CreateMcReadingSingleInput {
  CreateMcReadingSingleInput({
    required this.title,
    required this.promptText,
    required List<QuestionOptionInput> options,
  }) : options = List.unmodifiable(options);

  final String title;
  final String promptText;
  final List<QuestionOptionInput> options;

  CreateMcReadingSingleInput normalized() {
    final normalizedOptions = options
        .map((option) => option.normalized())
        .toList(growable: false);
    final normalizedTitle = title.trim();
    final normalizedPrompt = promptText.trim();

    if (normalizedTitle.isEmpty || normalizedPrompt.isEmpty) {
      throw const AuthoringValidationException(
        'Title and prompt are required.',
      );
    }
    if (normalizedOptions.length < 2 ||
        normalizedOptions.any((option) => option.text.isEmpty)) {
      throw const AuthoringValidationException(
        'At least two nonblank options are required.',
      );
    }
    for (var index = 0; index < normalizedOptions.length; index++) {
      if (normalizedOptions[index].orderIndex != index) {
        throw const AuthoringValidationException(
          'Option indexes must be contiguous from zero.',
        );
      }
    }
    if (normalizedOptions.where((option) => option.correct).length != 1) {
      throw const AuthoringValidationException(
        'Exactly one correct option is required.',
      );
    }

    return CreateMcReadingSingleInput(
      title: normalizedTitle,
      promptText: normalizedPrompt,
      options: normalizedOptions,
    );
  }
}

class AuthoringValidationException implements Exception {
  const AuthoringValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
