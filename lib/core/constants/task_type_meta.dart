/// Interaction family used by the design-system task templates.
enum TaskTemplateFamily {
  recordResponse,
  freeText,
  fillBlanks,
  multiSelect,
  ordering,
  singleSelect,
  tokenToggle,
}

/// Presentation metadata for one exam task type.
///
/// This registry is deliberately data-only. It is safe for core widgets and
/// preview tooling to consume without importing a feature BLoC or an API DTO.
class TaskTypeMeta {
  const TaskTypeMeta({
    required this.taskType,
    required this.section,
    required this.title,
    required this.instruction,
    required this.family,
    required this.scoringMode,
    required this.designReference,
  });

  final String taskType;
  final String section;
  final String title;
  final String instruction;
  final TaskTemplateFamily family;
  final String scoringMode;
  final String designReference;

  static const List<TaskTypeMeta> all = [
    TaskTypeMeta(
      taskType: 'PERSONAL_INTRODUCTION',
      section: 'SPEAKING',
      title: 'Personal Introduction',
      instruction: 'Introduce yourself using the prompts below.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'unscored',
      designReference: '11-personal-introduction',
    ),
    TaskTypeMeta(
      taskType: 'READ_ALOUD',
      section: 'SPEAKING',
      title: 'Read Aloud',
      instruction: 'Read the text aloud as naturally as possible.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '01-read-aloud',
    ),
    TaskTypeMeta(
      taskType: 'REPEAT_SENTENCE',
      section: 'SPEAKING',
      title: 'Repeat Sentence',
      instruction: 'Listen to the sentence and repeat it.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '13-repeat-sentence',
    ),
    TaskTypeMeta(
      taskType: 'DESCRIBE_IMAGE',
      section: 'SPEAKING',
      title: 'Describe Image',
      instruction: 'Describe the image in detail.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '14-describe-image',
    ),
    TaskTypeMeta(
      taskType: 'RE_TELL_LECTURE',
      section: 'SPEAKING',
      title: 'Re-tell Lecture',
      instruction: 'Re-tell the lecture in your own words.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '15-re-tell-lecture',
    ),
    TaskTypeMeta(
      taskType: 'ANSWER_SHORT_QUESTION',
      section: 'SPEAKING',
      title: 'Answer Short Question',
      instruction:
          'Listen to the question and answer with a word or short phrase.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '16-answer-short-question',
    ),
    TaskTypeMeta(
      taskType: 'SUMMARIZE_GROUP_DISCUSSION',
      section: 'SPEAKING',
      title: 'Summarize Group Discussion',
      instruction: 'Summarize the discussion in your own words.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: 'derived-audio-prompt-fallback',
    ),
    TaskTypeMeta(
      taskType: 'RESPOND_TO_A_SITUATION',
      section: 'SPEAKING',
      title: 'Respond to a Situation',
      instruction: 'Respond appropriately to the situation.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: 'derived-audio-prompt-fallback',
    ),
    TaskTypeMeta(
      taskType: 'SUMMARIZE_WRITTEN_TEXT',
      section: 'WRITING',
      title: 'Summarize Written Text',
      instruction: 'Summarize the passage in one sentence.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '17-summarize-written-text',
    ),
    TaskTypeMeta(
      taskType: 'WRITE_ESSAY',
      section: 'WRITING',
      title: 'Write Essay',
      instruction: 'Plan, write and revise an essay about the topic below.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '18-write-essay',
    ),
    TaskTypeMeta(
      taskType: 'SUMMARIZE_SPOKEN_TEXT',
      section: 'LISTENING',
      title: 'Summarize Spoken Text',
      instruction: 'Write a summary of the recording.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '26-summarize-spoken-text',
    ),
    TaskTypeMeta(
      taskType: 'WRITE_FROM_DICTATION',
      section: 'LISTENING',
      title: 'Write from Dictation',
      instruction: 'Type the sentence you hear.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '33-write-from-dictation-listening',
    ),
    TaskTypeMeta(
      taskType: 'FILL_BLANKS_READING_WRITING',
      section: 'READING',
      title: 'Reading and Writing: Fill in the Blanks',
      instruction: 'Select the best word for each blank.',
      family: TaskTemplateFamily.fillBlanks,
      scoringMode: 'reading-writing',
      designReference: '20-reading-writing-fill-in-the-blanks',
    ),
    TaskTypeMeta(
      taskType: 'MC_READING_MULTIPLE',
      section: 'READING',
      title: 'Multiple-Choice, Multiple Answer',
      instruction: 'Select all the correct responses.',
      family: TaskTemplateFamily.multiSelect,
      scoringMode: 'reading',
      designReference: '21-multiple-choice-multiple-answer',
    ),
    TaskTypeMeta(
      taskType: 'RE_ORDER_PARAGRAPHS',
      section: 'READING',
      title: 'Re-order Paragraphs',
      instruction: 'Re-order the paragraphs into the correct sequence.',
      family: TaskTemplateFamily.ordering,
      scoringMode: 'reading',
      designReference: '22-re-order-paragraphs',
    ),
    TaskTypeMeta(
      taskType: 'FILL_BLANKS_READING',
      section: 'READING',
      title: 'Reading: Fill in the Blanks',
      instruction: 'Drag the words into the correct blanks.',
      family: TaskTemplateFamily.fillBlanks,
      scoringMode: 'reading',
      designReference: '23-reading-fill-in-the-blanks',
    ),
    TaskTypeMeta(
      taskType: 'MC_READING_SINGLE',
      section: 'READING',
      title: 'Reading: Multiple Choice, Single Answer',
      instruction: 'Select the correct response.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'reading',
      designReference: '24-multiple-choice-single-answer',
    ),
    TaskTypeMeta(
      taskType: 'MC_LISTENING_MULTIPLE',
      section: 'LISTENING',
      title: 'Multiple-Choice, Multiple Answer',
      instruction: 'Select all the correct responses.',
      family: TaskTemplateFamily.multiSelect,
      scoringMode: 'listening',
      designReference: '27-multiple-choice-multiple-answer-listening',
    ),
    TaskTypeMeta(
      taskType: 'FILL_BLANKS_LISTENING',
      section: 'LISTENING',
      title: 'Listening: Fill in the Blanks',
      instruction: 'Type the missing words as you listen.',
      family: TaskTemplateFamily.fillBlanks,
      scoringMode: 'listening',
      designReference: '28-fill-in-the-blanks-listening',
    ),
    TaskTypeMeta(
      taskType: 'HIGHLIGHT_CORRECT_SUMMARY',
      section: 'LISTENING',
      title: 'Highlight Correct Summary',
      instruction: 'Select the summary that best represents the recording.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'listening',
      designReference: '29-highlight-correct-summary',
    ),
    TaskTypeMeta(
      taskType: 'MC_LISTENING_SINGLE',
      section: 'LISTENING',
      title: 'Multiple-Choice, Single Answer',
      instruction: 'Select the correct response.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'listening',
      designReference: '30-multiple-choice-single-answer-listening',
    ),
    TaskTypeMeta(
      taskType: 'SELECT_MISSING_WORD',
      section: 'LISTENING',
      title: 'Select Missing Word',
      instruction: 'Select the word that completes the recording.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'listening',
      designReference: '31-select-missing-word-listening',
    ),
    TaskTypeMeta(
      taskType: 'HIGHLIGHT_INCORRECT_WORDS',
      section: 'LISTENING',
      title: 'Highlight Incorrect Words',
      instruction: 'Select the words that differ from the recording.',
      family: TaskTemplateFamily.tokenToggle,
      scoringMode: 'listening',
      designReference: '32-highlight-incorrect-words-listening',
    ),
  ];

  static final Map<String, TaskTypeMeta> _byType = {
    for (final meta in all) meta.taskType: meta,
  };

  static TaskTypeMeta? forTaskType(String taskType) => _byType[taskType];
}
