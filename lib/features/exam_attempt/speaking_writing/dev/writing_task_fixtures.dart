/// Sample content for Summarize Written Text and Write Essay used during
/// development before the writing backend lands. Mimics the "replace when
/// questions load" TODO convention used by `core_test` and `reading`.
library;

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

const String kSummarizeWrittenTextInstruction =
    'Read the passage below and summarize it in one sentence (5 to 75 words).';

const String kSummarizeWrittenTextPassage = '''
In the late 19th century, the rapid expansion of urban centres across Europe created
unprecedented public-health challenges. Crowded tenements, contaminated water supplies,
and the absence of organised waste collection allowed cholera, typhus, and tuberculosis
to spread quickly through working-class districts. Local authorities, often reluctant to
intervene in what they regarded as private housing matters, responded slowly even as
death rates climbed. A handful of reformers, most famously Edwin Chadwick in Britain,
argued that sanitation was a collective responsibility: clean water, sewerage, and
ventilated streets would benefit everyone, rich and poor alike. Their reports persuaded
parliaments to pass sweeping public-health acts that funded municipal waterworks and
sewage systems, laying the foundation for the modern expectation that governments
take an active role in protecting the health of their citizens.
''';

const String kSummarizeWrittenTextMinWords = '5';
const String kSummarizeWrittenTextMaxWords = '75';
const int kSummarizeWrittenTextDurationSeconds = 600; // 10 minutes.

const String kWriteEssayInstruction =
    'You will have 20 minutes to plan, write and revise an essay about the topic below.';

const String kWriteEssayPrompt = '''
Some people believe that the most important function of universities is to prepare
students for their future careers. Others argue that universities should focus
primarily on broad personal development rather than vocational training.

Discuss both views and give your own opinion.
''';

const String kWriteEssayMinWords = '200';
const String kWriteEssayMaxWords = '300';
const int kWriteEssayDurationSeconds = 1200; // 20 minutes.

/// Hand-built [TaskView] samples for the two writing dev-preview screens
/// (Summarize Written Text + Write Essay). Mirrors the shape of
/// `SpeakingWritingTaskFixtures` so the existing picker can render them
/// through the real `TaskTypeDispatcher`.
class WritingTaskFixtures {
  const WritingTaskFixtures._();

  static TaskView get summarizeWrittenText {
    return TaskView(
      pinnedItemPublicId: 'fixture-SUMMARIZE_WRITTEN_TEXT',
      orderIndex: 0,
      totalTasks: 2,
      section: 'WRITING',
      taskType: 'SUMMARIZE_WRITTEN_TEXT',
      title: 'Sample SUMMARIZE_WRITTEN_TEXT',
      promptText: kSummarizeWrittenTextPassage,
      minWordCount: int.parse(kSummarizeWrittenTextMinWords),
      maxWordCount: int.parse(kSummarizeWrittenTextMaxWords),
      prepSeconds: 0,
      responseSeconds: kSummarizeWrittenTextDurationSeconds,
    );
  }

  static TaskView get writeEssay {
    return TaskView(
      pinnedItemPublicId: 'fixture-WRITE_ESSAY',
      orderIndex: 1,
      totalTasks: 2,
      section: 'WRITING',
      taskType: 'WRITE_ESSAY',
      title: 'Sample WRITE_ESSAY',
      promptText: kWriteEssayPrompt,
      minWordCount: int.parse(kWriteEssayMinWords),
      maxWordCount: int.parse(kWriteEssayMaxWords),
      prepSeconds: 0,
      responseSeconds: kWriteEssayDurationSeconds,
    );
  }

  static List<TaskView> get all => [summarizeWrittenText, writeEssay];
}
