import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Hand-built [TaskView] samples, one per listening task type, for the
/// `kDebugMode`-gated dev preview screen — mirrors [ReadingTaskFixtures].
/// Not sourced from a real backend response: `exam-delivery` has zero
/// routing/timing config for any of these 8 types today (plan.md Risks),
/// so this is the only way to see the screens before the backend catches
/// up. `audioPromptRef` points at a bundled silent placeholder `.wav`
/// asset (no real PTE audio content — see phase-01 Risks on licensing).
class ListeningTaskFixtures {
  const ListeningTaskFixtures._();

  static TaskView _base({
    required String taskType,
    String? promptText,
    required String audioPromptRef,
    List<TaskOption>? options,
    int? minWordCount,
    int? maxWordCount,
  }) {
    return TaskView(
      pinnedItemPublicId: 'fixture-$taskType',
      orderIndex: 0,
      totalTasks: 8,
      section: 'LISTENING',
      taskType: taskType,
      title: 'Sample $taskType',
      promptText: promptText,
      audioPromptRef: audioPromptRef,
      options: options,
      minWordCount: minWordCount,
      maxWordCount: maxWordCount,
      prepSeconds: 0,
      responseSeconds: 120,
    );
  }

  static TaskView get writeFromDictation => _base(
    taskType: 'WRITE_FROM_DICTATION',
    audioPromptRef: 'assets/audio/listening_sample_dictation.wav',
  );

  static TaskView get summarizeSpokenText => _base(
    taskType: 'SUMMARIZE_SPOKEN_TEXT',
    audioPromptRef: 'assets/audio/listening_sample_summarize.wav',
    minWordCount: 50,
    maxWordCount: 70,
  );

  static TaskView get mcListeningSingle => _base(
    taskType: 'MC_LISTENING_SINGLE',
    audioPromptRef: 'assets/audio/listening_sample_mc_single.wav',
    options: const [
      TaskOption(text: 'The company relocated its headquarters.', orderIndex: '0'),
      TaskOption(text: 'The company hired more staff.', orderIndex: '1'),
      TaskOption(text: 'The company reduced its prices.', orderIndex: '2'),
    ],
  );

  static TaskView get mcListeningMultiple => _base(
    taskType: 'MC_LISTENING_MULTIPLE',
    audioPromptRef: 'assets/audio/listening_sample_mc_multiple.wav',
    options: const [
      TaskOption(text: 'rising sea levels', orderIndex: '0'),
      TaskOption(text: 'declining fish stocks', orderIndex: '1'),
      TaskOption(text: 'coral bleaching', orderIndex: '2'),
      TaskOption(text: 'improved water clarity', orderIndex: '3'),
    ],
  );

  static TaskView get selectMissingWord => _base(
    taskType: 'SELECT_MISSING_WORD',
    audioPromptRef: 'assets/audio/listening_sample_select_missing_word.wav',
    options: const [
      TaskOption(text: 'continue', orderIndex: '0'),
      TaskOption(text: 'accept', orderIndex: '1'),
      TaskOption(text: 'repeat', orderIndex: '2'),
      TaskOption(text: 'follow', orderIndex: '3'),
    ],
  );

  static TaskView get highlightCorrectSummary => _base(
    taskType: 'HIGHLIGHT_CORRECT_SUMMARY',
    audioPromptRef: 'assets/audio/listening_sample_highlight_correct_summary.wav',
    options: const [
      TaskOption(
        text: 'The lecture argues that urban green spaces reduce city temperatures and improve air quality.',
        orderIndex: '0',
      ),
      TaskOption(
        text: 'The lecture argues that public transport is the most effective way to reduce emissions.',
        orderIndex: '1',
      ),
      TaskOption(
        text: 'The lecture argues that recycling programs have failed to reduce landfill waste.',
        orderIndex: '2',
      ),
    ],
  );

  static TaskView get highlightIncorrectWords => _base(
    taskType: 'HIGHLIGHT_INCORRECT_WORDS',
    audioPromptRef: 'assets/audio/listening_sample_highlight_incorrect_words.wav',
    promptText:
        'For some people, this presentation may seem far fetched, but ending poverty is both ethically '
        'necessary and actually feasible.',
  );

  static TaskView get fillBlanksListening => _base(
    taskType: 'FILL_IN_THE_BLANKS_TYPE_IN',
    audioPromptRef: 'assets/audio/listening_sample_fill_blanks.wav',
    promptText:
        'And one particular crop, almond in the US and now in Australia, is transforming the world of '
        '{{0}} and lawns. What has happened is that something serendipitous came along that people '
        'had not, that doctors had not foreseen was good for you, and it is the {{1}} board of a very '
        'aggressive promotion going on for almonds.',
  );

  static List<TaskView> get all => [
    writeFromDictation,
    summarizeSpokenText,
    mcListeningSingle,
    mcListeningMultiple,
    selectMissingWord,
    highlightCorrectSummary,
    highlightIncorrectWords,
    fillBlanksListening,
  ];
}
