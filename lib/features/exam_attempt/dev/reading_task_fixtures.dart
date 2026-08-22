import '../domain/task_view.dart';

/// Hand-built [TaskView] samples, one per reading task type, for widget
/// tests and the `kDebugMode`-gated dev preview screen. Not sourced from a
/// real backend response — `FILL_BLANKS_READING_WRITING` in particular has
/// no live backend content until the plan's backend phases ship
/// `blankGroups`-populated data (see `ninh-pte-reading-task-types` plan.md).
class ReadingTaskFixtures {
  const ReadingTaskFixtures._();

  static TaskView _base({
    required String taskType,
    required String promptText,
    List<TaskOption>? options,
    List<BlankGroup>? blankGroups,
  }) {
    final now = DateTime(2026, 1, 1, 9);
    return TaskView(
      pinnedItemPublicId: 'fixture-$taskType',
      orderIndex: 0,
      totalTasks: 5,
      section: 'READING',
      taskType: taskType,
      title: 'Sample $taskType',
      promptText: promptText,
      options: options,
      blankGroups: blankGroups,
      prepSeconds: 0,
      responseSeconds: 120,
      prepDeadline: now,
      responseDeadline: now.add(const Duration(minutes: 2)),
      serverNow: now,
    );
  }

  static TaskView get mcReadingSingle => _base(
    taskType: 'MC_READING_SINGLE',
    promptText:
        'In the summer of 1914, a ship called the Endurance departed London for the South Pole. '
        'The captain was Ernest Shackleton, a famous Irish explorer.',
    options: const [
      TaskOption(text: 'They were lost.', orderIndex: '0'),
      TaskOption(text: 'The ship was stuck in ice.', orderIndex: '1'),
      TaskOption(text: 'The ship was destroyed.', orderIndex: '2'),
    ],
  );

  static TaskView get mcReadingMultiple => _base(
    taskType: 'MC_READING_MULTIPLE',
    promptText:
        'At the end of the day, the sun goes down but our cities light up. Billboards, office '
        'buildings, streetlights, cars, and many other things illuminate the sky.',
    options: const [
      TaskOption(text: 'health problems in humans', orderIndex: '0'),
      TaskOption(text: 'people sleeping longer', orderIndex: '1'),
      TaskOption(text: 'trees dying', orderIndex: '2'),
      TaskOption(text: 'birds getting lost', orderIndex: '3'),
    ],
  );

  static TaskView get reOrderParagraphs => _base(
    taskType: 'RE_ORDER_PARAGRAPHS',
    promptText: '',
    options: const [
      TaskOption(text: 'Finally, the team published their findings in a major journal.', orderIndex: '3'),
      TaskOption(text: 'First, the researchers gathered samples from three different sites.', orderIndex: '0'),
      TaskOption(text: 'The samples were then analyzed over several months.', orderIndex: '1'),
      TaskOption(text: 'Unexpected patterns emerged from the analysis.', orderIndex: '2'),
    ],
  );

  static TaskView get fillBlanksReading => _base(
    taskType: 'FILL_BLANKS_READING',
    promptText:
        'An anti-fairy tale which, unlike an ordinary one, has a {{0}}, rather than a happy ending, '
        'with the main characters suffering loss. While fairy tales paint a magical world, anti-fairy '
        'tales paint a dark world full of {{1}} and cruelty.',
    options: const [
      TaskOption(text: 'tragic', orderIndex: '0'),
      TaskOption(text: 'boring', orderIndex: '1'),
      TaskOption(text: 'happiness', orderIndex: '2'),
      TaskOption(text: 'twists', orderIndex: '3'),
      TaskOption(text: 'nastiness', orderIndex: '4'),
      TaskOption(text: 'events', orderIndex: '5'),
    ],
  );

  /// `blankGroups` is populated here for local/offline preview and widget
  /// tests only — no live backend can send this yet (see class doc).
  static TaskView get fillBlanksReadingWriting => _base(
    taskType: 'FILL_BLANKS_READING_WRITING',
    promptText:
        'Lighting uses about 25% of the world\'s electricity, but it is not always used {{0}}. Some '
        'lights are kept on even when there is nobody {{1}} them.',
    blankGroups: const [
      BlankGroup(
        blankIndex: 0,
        options: [
          TaskOption(text: 'efficiently', orderIndex: '0'),
          TaskOption(text: 'quickly', orderIndex: '1'),
          TaskOption(text: 'rarely', orderIndex: '2'),
        ],
      ),
      BlankGroup(
        blankIndex: 1,
        options: [
          TaskOption(text: 'using', orderIndex: '0'),
          TaskOption(text: 'needing', orderIndex: '1'),
          TaskOption(text: 'building', orderIndex: '2'),
        ],
      ),
    ],
  );

  /// Same task type as [fillBlanksReadingWriting] but with `blankGroups`
  /// absent, matching what a live backend returns before the plan's
  /// backend phases ship — used to test/preview the `StatusBanner`
  /// fallback.
  static TaskView get fillBlanksReadingWritingUnavailable => _base(
    taskType: 'FILL_BLANKS_READING_WRITING',
    promptText: 'Lighting uses about 25% of the world\'s electricity.',
  );

  static List<TaskView> get all => [
    mcReadingSingle,
    mcReadingMultiple,
    reOrderParagraphs,
    fillBlanksReading,
    fillBlanksReadingWriting,
  ];
}
