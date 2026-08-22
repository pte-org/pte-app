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

  /// `prepSeconds: 10` is a sum, not a single stage's duration — the
  /// real-world sequence is 3s pre-listen prep + 4s mocked audio playback +
  /// 3s pre-record prep (`RepeatSentenceScreen` renders each of the 2
  /// cards' own "Beginning in…"/"Playing…" sub-stage independently, derived
  /// from this total).
  ///
  /// Deliberately **10**, not the originally-discussed 12 (3+6+3): the dev
  /// preview's `ExamAttemptBloc` polls every 10s by default (production
  /// code, not something dev tooling overrides) and only adopts a new
  /// `TimerPhase` from a poll response — a `prepSeconds` that doesn't land
  /// on a poll boundary leaves the UI stuck showing "Beginning in 0
  /// seconds" for up to one whole extra poll interval after the local
  /// countdown reaches zero, before the next poll actually flips the phase
  /// and lets `onTimerSnapshot` start recording. Landing exactly on a
  /// 10s boundary keeps that lag effectively zero. See the identical
  /// alignment choice on `readAloud`'s `prepSeconds: 30` above.
  static TaskView get repeatSentence {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 10;
    const responseSeconds = 15;
    return TaskView(
      pinnedItemPublicId: 'fixture-REPEAT_SENTENCE',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'REPEAT_SENTENCE',
      title: 'Sample REPEAT_SENTENCE',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(const Duration(seconds: prepSeconds + responseSeconds)),
      serverNow: now,
    );
  }

  static List<TaskView> get all => [readAloud, repeatSentence];
}
