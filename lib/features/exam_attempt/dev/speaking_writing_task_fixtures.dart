import '../domain/task_view.dart';

/// Hand-built [TaskView] samples for the Speaking/Writing dev preview —
/// same purpose as `ReadingTaskFixtures`, kept in a separate file since
/// these tasks are neither reading task types nor sourced from a real
/// backend response. `prepSeconds`/`responseSeconds` are shortened well
/// below the real PTE timings so the auto-record transition is quick to
/// observe in the dev preview — never used outside `kDebugMode` tooling.
class SpeakingWritingTaskFixtures {
  const SpeakingWritingTaskFixtures._();

  static TaskView get readAloud {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 8;
    const responseSeconds = 15;
    return TaskView(
      pinnedItemPublicId: 'fixture-READ_ALOUD',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'READ_ALOUD',
      title: 'Sample READ_ALOUD',
      promptText:
          'The basic premise in the management of any system is the ability to minimize risk. In the '
          'context of an ecosystem, one of the important questions is the integrity of the environment '
          'and how this integrity is compromised by management.',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(const Duration(seconds: prepSeconds + responseSeconds)),
      serverNow: now,
    );
  }

  static List<TaskView> get all => [readAloud];
}
