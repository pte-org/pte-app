import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/fill_blanks_listening_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/fill_blanks_listening_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/fill_blanks_listening_text.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_audio_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// StatefulWidget owning one `TextEditingController` per gap (the cubit
/// owns none — phase-05 Design Constraints, extends phase-02's corrected
/// screen-owns-controllers split to N controllers instead of 1).
class FillBlanksListeningScreen extends StatefulWidget {
  const FillBlanksListeningScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioPlayerService,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioPlayerService audioPlayerService;

  @override
  State<FillBlanksListeningScreen> createState() => _FillBlanksListeningScreenState();
}

class _FillBlanksListeningScreenState extends State<FillBlanksListeningScreen> {
  late final FillBlanksListeningCubit _cubit;
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final promptText = widget.task.promptText ?? '';
    final gapCount = parseBlankPrompt(promptText).whereType<PromptGapSegment>().length;
    _cubit = FillBlanksListeningCubit(
      outboxDao: widget.outboxDao,
      audioPlayerService: widget.audioPlayerService,
      attemptPublicId: widget.attemptPublicId,
      pinnedItemPublicId: widget.task.pinnedItemPublicId,
      gapCount: gapCount,
      audioSource: widget.task.audioPromptRef ?? '',
    );
    _controllers = [
      for (var gapIndex = 0; gapIndex < gapCount; gapIndex++)
        TextEditingController()..addListener(() {
          final index = gapIndex;
          _cubit.gapChanged(index, _controllers[index].text);
        }),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: ExamScaffold(
        totalTasks: widget.task.totalTasks,
        body: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: BlocBuilder<FillBlanksListeningCubit, FillBlanksListeningState>(
            builder: (context, state) {
              return Column(
                children: [
                  ListeningAudioBar(hasFinishedPlaying: state.hasFinishedPlaying),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Expanded(
                    child: SingleChildScrollView(
                      child: FillBlanksListeningText(
                        promptText: widget.task.promptText ?? '',
                        controllers: _controllers,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomAction: TaskAdvanceButton(
          cubit: _cubit,
          pinnedItemPublicId: widget.task.pinnedItemPublicId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }
}
