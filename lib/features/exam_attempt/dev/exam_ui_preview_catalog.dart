import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/dev/listening_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/reading_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/task_view_ui_adapter.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart';

/// Complete, deterministic task set for UI review when pte-api is unavailable.
/// The catalog contains data only; it never creates a cubit, calls an API,
/// writes an outbox row, opens a microphone, or submits an attempt.
class ExamUiPreviewCatalog {
  const ExamUiPreviewCatalog._();

  static final List<TaskView> tasks = [
    ...ReadingTaskFixtures.all,
    ...ListeningTaskFixtures.all,
    ...SpeakingWritingTaskFixtures.all,
    ...WritingTaskFixtures.all,
  ];

  static final List<ExamTaskUiModel> models = [
    for (final task in tasks)
      TaskViewUiAdapter.adapt(task, origin: DataOrigin.fixture),
  ];

  static ExamTaskUiModel modelFor(String taskType) => models.singleWhere(
    (model) =>
        model.taskType == (TaskTypeCodes.canonicalize(taskType) ?? taskType),
    orElse: () => throw ArgumentError.value(taskType, 'taskType'),
  );
}
