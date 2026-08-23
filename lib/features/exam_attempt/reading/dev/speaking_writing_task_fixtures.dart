import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Hand-built [TaskView] samples for the Speaking/Writing dev preview —
/// same purpose as `ReadingTaskFixtures`, kept in a separate file since
/// these tasks are neither reading task types nor sourced from a real
/// backend response. Real PTE Read Aloud tasks vary their prep/response
/// window per question (fetched from the backend); this fixture mocks
/// ~30s prep / ~40s response — the current best-known typical values,
/// never used outside `kDebugMode` tooling.
class SpeakingWritingTaskFixtures {
  const SpeakingWritingTaskFixtures._();

  /// `prepSeconds: 25`/`responseSeconds: 30` are the user's literal mock
  /// values — same as [describeImage]'s fixture, neither lands on the
  /// dev-preview `ExamAttemptBloc`'s 10-second poll boundary (nearest
  /// boundaries 20/30 and 50/60), and unlike the sub-staged fixtures
  /// ([repeatSentence], [retellLecture], [answerShortQuestion]) there is no
  /// internal sub-stage split to redistribute seconds within to hit one —
  /// `PERSONAL_INTRODUCTION` has no audio-listening sub-stage at all. This
  /// means up to ~5-9s of dev-preview-ONLY UI lag is expected at both
  /// transitions, never a production concern (see [describeImage]'s doc
  /// comment for the identical tradeoff and rationale).
  static TaskView get personalIntroduction {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 25;
    const responseSeconds = 30;
    return TaskView(
      pinnedItemPublicId: 'fixture-PERSONAL_INTRODUCTION',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'PERSONAL_INTRODUCTION',
      title: 'Sample PERSONAL_INTRODUCTION',
      promptText:
          'Please introduce yourself. For example, you could talk about one or more of the following:\n\n'
          '• Your interests\n'
          '• Your plans for future study\n'
          '• Why you want to study abroad\n'
          '• Why you need to learn English\n'
          '• Why you chose this test',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

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
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
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
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

  /// `prepSeconds: 25`/`responseSeconds: 40` are the user's literal,
  /// non-negotiable mock values — unlike `readAloud`'s `prepSeconds: 30`
  /// and `repeatSentence`'s `prepSeconds: 10`, which were deliberately
  /// rounded to land on the dev-preview `ExamAttemptBloc`'s 10s poll
  /// boundary, neither `25` (prep→response, nearest boundaries 20/30) nor
  /// `65` (prep+response, response→recorded, nearest boundaries 60/70)
  /// lands on a boundary here. This means up to ~5s of dev-preview-ONLY UI
  /// lag is expected at both transitions — the local countdown can reach
  /// zero before the next poll response actually flips `TimerPhase` and
  /// lets `onTimerSnapshot` start/stop recording. This is never a
  /// production concern: production timing comes from real server-pushed
  /// `prepDeadline`/`responseDeadline`, not this fixture's local
  /// `DateTime.now()`-based construction. Do **not** "fix" this by
  /// rounding 25/40 to poll-aligned numbers — the literal values are an
  /// explicit user requirement, not a default this file chose.
  ///
  /// `imagePromptRef` points at a real public placeholder image
  /// (Picsum Photos, seeded so the image is stable/reproducible across
  /// reloads) — unlike every other fixture in this file, selecting this
  /// one from the dev-preview picker requires real network connectivity
  /// for the image to actually load (`TaskImageDisplay`'s `errorBuilder`
  /// covers the offline case gracefully, but the picture itself won't
  /// render without a connection).
  static TaskView get describeImage {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 25;
    const responseSeconds = 40;
    return TaskView(
      pinnedItemPublicId: 'fixture-DESCRIBE_IMAGE',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'DESCRIBE_IMAGE',
      title: 'Sample DESCRIBE_IMAGE',
      imagePromptRef:
          'https://picsum.photos/seed/describe-image-fixture/800/600',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

  /// `prepSeconds: 70` is a sum of 3 mocked sub-stages: 3s pre-listen prep
  /// + 57s mocked lecture-audio playback + 10s pre-record "chuẩn bị" prep
  /// (`3 + 57 + 10 = 70`) — same 3-stage shape as [repeatSentence]'s split,
  /// just with a longer audio stage and a longer pre-record stage. The 57s
  /// audio duration is a deliberate rounding-down from the originally-
  /// discussed ~60s, kept to land `prepSeconds` on `70`.
  ///
  /// Both `70` (prep→response) and `110` (`prepSeconds + responseSeconds`,
  /// response→recorded) land exactly on the dev-preview `ExamAttemptBloc`'s
  /// 10-second poll boundary — same alignment goal as [readAloud]'s
  /// `prepSeconds: 30` and [repeatSentence]'s `prepSeconds: 10`, avoiding
  /// the "Beginning in 0 seconds" stuck-UI dev-preview-only lag (see
  /// [repeatSentence]'s doc comment), unlike [describeImage]'s fixture,
  /// which deliberately keeps its literal, non-boundary-aligned `25`/`40`
  /// values and accepts the resulting lag.
  static TaskView get retellLecture {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 70;
    const responseSeconds = 40;
    return TaskView(
      pinnedItemPublicId: 'fixture-RE_TELL_LECTURE',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'RE_TELL_LECTURE',
      title: 'Sample RE_TELL_LECTURE',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

  /// `prepSeconds: 14` is the sum of 3 mocked sub-stages: 3s pre-listen prep
  /// + 8s mocked audio playback + 3s pre-record "chuẩn bị" prep (`3 + 8 + 3
  /// = 14`) — same 3-stage shape as [repeatSentence]'s split (identical
  /// `_preListenSeconds`/`_preRecordSeconds` = 3/3), just a shorter audio
  /// stage. `responseSeconds: 10` is the recording window.
  ///
  /// Unlike [retellLecture]'s fixture, `14` (prep→response) and `24`
  /// (`prepSeconds + responseSeconds`, response→recorded) do **not** land on
  /// the dev-preview `ExamAttemptBloc`'s 10-second poll boundary — these are
  /// the user's literal, non-negotiable mock values (3s/8s/3s/10s), kept as
  /// given rather than rounded to a boundary. This means a small
  /// dev-preview-ONLY UI lag is expected at both transitions (see
  /// [describeImage]'s doc comment for the identical tradeoff and why it's
  /// never a production concern).
  static TaskView get answerShortQuestion {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 14;
    const responseSeconds = 10;
    return TaskView(
      pinnedItemPublicId: 'fixture-ANSWER_SHORT_QUESTION',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'ANSWER_SHORT_QUESTION',
      title: 'Sample ANSWER_SHORT_QUESTION',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

  /// `prepSeconds: 200` is a sum of 3 mocked sub-stages: 5s pre-listen prep
  /// + 185s mocked group-discussion-audio playback + 10s pre-record "chuẩn
  /// bị" prep (`5 + 185 + 10 = 200`) — same 3-stage shape as
  /// [retellLecture]'s split. The 185s audio duration is a deliberate
  /// rounding-down from the originally-discussed ~180s (3 minutes),
  /// user-confirmed, kept to land `prepSeconds` on `200`.
  ///
  /// Both `200` (prep→response) and `320` (`prepSeconds + responseSeconds`,
  /// response→recorded) land exactly on the dev-preview `ExamAttemptBloc`'s
  /// 10-second poll boundary — same alignment goal as [retellLecture]'s
  /// fixture, avoiding the "Beginning in 0 seconds" stuck-UI dev-preview-only
  /// lag (see [repeatSentence]'s doc comment).
  static TaskView get summarizeGroupDiscussion {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 200;
    const responseSeconds = 120;
    return TaskView(
      pinnedItemPublicId: 'fixture-SUMMARIZE_GROUP_DISCUSSION',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'SUMMARIZE_GROUP_DISCUSSION',
      title: 'Sample SUMMARIZE_GROUP_DISCUSSION',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

  /// `prepSeconds: 40` is a sum of 3 mocked sub-stages: 20s pre-listen prep
  /// (itself a merge of "15s reading the situation + 5s waiting for audio",
  /// per user decision — see `RespondToASituationScreen`'s doc comment) +
  /// 10s mocked audio playback (the situation re-read aloud) + 10s
  /// pre-record "chuẩn bị" prep (`20 + 10 + 10 = 40`). `responseSeconds: 40`
  /// is the recording window.
  ///
  /// Both `40` (prep→response) and `80` (`prepSeconds + responseSeconds`,
  /// response→recorded) already land exactly on the dev-preview
  /// `ExamAttemptBloc`'s 10-second poll boundary — no rounding needed here,
  /// unlike [retellLecture]'s/[summarizeGroupDiscussion]'s fixtures.
  static TaskView get respondToASituation {
    final now = DateTime(2026, 1, 1, 9);
    const prepSeconds = 40;
    const responseSeconds = 40;
    return TaskView(
      pinnedItemPublicId: 'fixture-RESPOND_TO_A_SITUATION',
      orderIndex: 0,
      totalTasks: 5,
      section: 'SPEAKING',
      taskType: 'RESPOND_TO_A_SITUATION',
      title: 'Sample RESPOND_TO_A_SITUATION',
      promptText:
          'You are a student at a university. You have realized that you will miss an important exam because '
          'of a family emergency. Explain the situation to your professor and ask what you should do.',
      prepSeconds: prepSeconds,
      responseSeconds: responseSeconds,
      prepDeadline: now.add(const Duration(seconds: prepSeconds)),
      responseDeadline: now.add(
        const Duration(seconds: prepSeconds + responseSeconds),
      ),
      serverNow: now,
    );
  }

  static List<TaskView> get all => [
    personalIntroduction,
    readAloud,
    repeatSentence,
    describeImage,
    retellLecture,
    answerShortQuestion,
    summarizeGroupDiscussion,
    respondToASituation,
  ];
}
