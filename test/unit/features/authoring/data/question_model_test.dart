import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/authoring/data/models/question_model.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';

void main() {
  Map<String, dynamic> fixture({
    String taskType = 'MC_READING_SINGLE',
    String visibility = 'PRIVATE',
  }) {
    return {
      'publicId': 'question-1',
      'pteTaskType': taskType,
      'section': 'READING',
      'visibility': visibility,
      'tenantId': visibility == 'PRIVATE' ? 'tenant-1' : null,
      'status': 'DRAFT',
      'title': 'Question',
      'promptText': 'Choose one',
      'audioPromptRef': null,
      'imagePromptRef': null,
      'referenceAnswerText': null,
      'correctAnswerText': null,
      'minWordCount': null,
      'maxWordCount': null,
      'options': [
        {'publicId': 'option-1', 'text': 'A', 'correct': true, 'orderIndex': 0},
        {
          'publicId': 'option-2',
          'text': 'B',
          'correct': false,
          'orderIndex': 1,
        },
      ],
      'skills': ['READING'],
    };
  }

  test('parses complete private question response into domain entity', () {
    final question = QuestionModel.fromJson(fixture()).toEntity();

    expect(question.pteTaskType, PteTaskType.mcReadingSingle);
    expect(question.visibility, QuestionVisibility.private);
    expect(question.tenantId, 'tenant-1');
    expect(
      question.options.singleWhere((option) => option.correct).orderIndex,
      0,
    );
    expect(question.skills, ['READING']);
  });

  test('parses shared question with null tenant', () {
    final question = QuestionModel.fromJson(
      fixture(visibility: 'SHARED'),
    ).toEntity();

    expect(question.visibility, QuestionVisibility.shared);
    expect(question.tenantId, isNull);
  });

  test('unknown task type and visibility fail fast', () {
    expect(
      () => QuestionModel.fromJson(fixture(taskType: 'UNKNOWN')),
      throwsFormatException,
    );
    expect(
      () => QuestionModel.fromJson(fixture(visibility: 'GLOBAL')),
      throwsFormatException,
    );
  });
}
