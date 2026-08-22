import '../domain/task_view.dart';

/// Hand-built [TaskView] samples for the Speaking/Writing dev preview —
/// same purpose as `ReadingTaskFixtures`, kept in a separate file since
/// these tasks are neither reading task types nor sourced from a real
/// backend response. Real PTE Read Aloud tasks vary their prep/response
/// window per question (fetched from the backend); this fixture mocks
/// ~30s prep / ~40s response — the current best-known typical values,
/// never used outside `kDebugMode` tooling.
class SpeakingWritingTaskFixtures {
  const SpeakingWritingTaskFixtures._();

  static TaskView get readAloud {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 30;
    const responseSeconds = 40;
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
