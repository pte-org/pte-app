import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/dev/listening_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/reading_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';

/// Exam content the mock backend serves. Reuses the same hand-built fixtures
/// as the offline UI catalog so both dev paths show identical tasks; a
/// session's composition picks fixtures by task type.
abstract final class MockExamTasks {
  static const fullExamSessionId = 'mock-full-exam';

  /// A bundled (silent) clip — `just_audio` resolves the `asset:` scheme
  /// itself, so the audio-prompt Speaking screens play it offline.
  static const audioPromptUrl =
      'asset:///assets/audio/listening_sample_mc_single.wav';

  /// DESCRIBE_IMAGE needs a real network image (`Image.network`); offline,
  /// `TaskImageDisplay` falls back to its load-error label.
  static const describeImageUrl =
      'https://picsum.photos/seed/pte-describe-image/800/600';

  static const _audioPromptTaskTypes = {
    'REPEAT_SENTENCE',
    'RE_TELL_LECTURE',
    'ANSWER_SHORT_QUESTION',
    'SUMMARIZE_GROUP_DISCUSSION',
    'RESPOND_TO_A_SITUATION',
  };

  static List<TaskView> get speaking => SpeakingWritingTaskFixtures.all;
  static List<TaskView> get writing => WritingTaskFixtures.all;
  static List<TaskView> get reading => ReadingTaskFixtures.all;
  static List<TaskView> get listening => ListeningTaskFixtures.all;

  /// Seeded OPEN sessions, in real PTE section order
  /// (Speaking & Writing → Reading → Listening).
  static Map<String, List<TaskView>> get sessionTaskSets => {
    fullExamSessionId: [...speaking, ...writing, ...reading, ...listening],
    'mock-speaking': speaking,
    'mock-writing': writing,
    'mock-reading': reading,
    'mock-listening': listening,
  };

  /// Resolves a scheduling composition (`[{taskType, orderIndex, ...}]`) to
  /// fixture tasks; task types without a fixture are skipped.
  static List<TaskView> tasksForComposition(List<dynamic> composition) {
    final byType = {
      for (final task in [...speaking, ...writing, ...reading, ...listening])
        task.taskType: task,
    };
    final items = composition.cast<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => (a['orderIndex'] as int).compareTo(b['orderIndex'] as int),
      );
    return [for (final item in items) ?byType[item['taskType']]];
  }

  static Map<String, dynamic> taskJson(
    TaskView task, {
    required String pinnedItemPublicId,
    required int orderIndex,
    required int totalTasks,
  }) => {
    'pinnedItemPublicId': pinnedItemPublicId,
    'orderIndex': orderIndex,
    'totalTasks': totalTasks,
    'section': task.section,
    'taskType': task.taskType,
    'title': task.title,
    'promptText': task.promptText,
    // The fixtures leave this null for the 5 audio-prompt Speaking types,
    // which would make `AudioPromptCubit` skip playback entirely.
    'audioPromptRef': _audioPromptTaskTypes.contains(task.taskType)
        ? 'mock-media-audio-${task.taskType}'
        : task.audioPromptRef,
    'imagePromptRef': task.imagePromptRef,
    'imageUrl': task.taskType == 'DESCRIBE_IMAGE'
        ? describeImageUrl
        : task.imageUrl,
    'minWordCount': task.minWordCount,
    'maxWordCount': task.maxWordCount,
    'options': task.options?.map(_optionJson).toList(),
    'blankGroups': task.blankGroups
        ?.map(
          (group) => {
            'blankIndex': group.blankIndex,
            'options': group.options.map(_optionJson).toList(),
          },
        )
        .toList(),
    'prepSeconds': task.prepSeconds,
    'responseSeconds': task.responseSeconds,
    'preListenSeconds': task.preListenSeconds,
    'preRecordSeconds': task.preRecordSeconds,
  };

  static Map<String, dynamic> _optionJson(TaskOption option) => {
    'text': option.text,
    'orderIndex': option.orderIndex,
  };
}
