import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/templates/exam_task_frame.dart';
import 'package:pte_app/core/widgets/templates/exam_template_frame.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_panel.dart';
import 'task_image_display.dart';
import 'package:pte_app/core/widgets/templates/status_speaking_task_frame.dart';

export 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_prompt_sub_stage.dart';
export 'audio_prompt_record_panel.dart';

/// Shared body for Speaking tasks whose prompt is played before recording.
///
/// The candidate sees one PTE-style audio surface. It starts as an Audio
/// Player and changes to an Audio Recorder when playback completes or the
/// server-owned pre-record window begins. The five task screens share this
/// composition, while their cubits continue to own playback and recording.
class AudioPromptRecordBody extends StatelessWidget {
  const AudioPromptRecordBody({
    super.key,
    required this.task,
    required this.preListenSeconds,
    required this.preRecordSeconds,
    required this.instructionText,
  });

  final TaskView task;
  final int preListenSeconds;
  final int preRecordSeconds;
  final String instructionText;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>(
      selector: (state) =>
          state is AttemptInProgress ? state.timerSnapshot : null,
      builder: (context, snapshot) {
        return BlocBuilder<AutoRecordCubit, AutoRecordState>(
          builder: (context, recordingState) {
            return BlocBuilder<AudioPromptCubit, AudioPromptPlaybackState>(
              builder: (context, playback) {
                final panel = AudioPromptRecordPanel(
                  task: task,
                  snapshot: snapshot,
                  playback: playback,
                  recordingState: recordingState,
                  preListenSeconds: preListenSeconds,
                  preRecordSeconds: preRecordSeconds,
                  inputLevels: context.read<AutoRecordCubit>().inputLevels,
                );
                return _buildFrame(panel);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFrame(Widget panel) {
    final title = TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title;
    final imageUrl = task.imageUrl;
    if (usesStatusAudioPanels(task.taskType)) {
      return StatusSpeakingTaskFrame(
        taskType: task.taskType,
        title: title,
        instruction: instructionText,
        promptText: task.promptText,
        panels: panel,
        image: imageUrl == null ? null : TaskImageDisplay(imageUrl: imageUrl),
      );
    }
    if (imageUrl == null) {
      return ExamTaskFrame(
        title: title,
        instruction: instructionText,
        body: panel,
      );
    }
    return ExamTemplateFrame(
      layout: ExamTemplateLayout.split,
      title: title,
      subtitle: task.section,
      instruction: instructionText,
      stimulus: SingleChildScrollView(
        child: TaskImageDisplay(imageUrl: imageUrl),
      ),
      response: panel,
    );
  }
}
