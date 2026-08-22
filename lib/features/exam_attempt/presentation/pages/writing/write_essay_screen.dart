import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../../core/sync/sync_engine.dart';
import '../../../domain/task_view.dart';
import '../../cubit/write_essay_cubit.dart';
import '../../widgets/exam_scaffold.dart';
import '../../widgets/task_advance_button.dart';
import '../../widgets/word_count_label.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05 Design
/// Constraints). The [TextEditingController] is created in [initState] and
/// disposed in [dispose]; it is never recreated across rebuilds.
class WriteEssayScreen extends StatefulWidget {
  const WriteEssayScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;

  @override
  State<WriteEssayScreen> createState() => _WriteEssayScreenState();
}

class _WriteEssayScreenState extends State<WriteEssayScreen> {
  late final WriteEssayCubit _cubit;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _cubit = WriteEssayCubit(
      outboxDao: widget.outboxDao,
      attemptPublicId: widget.attemptPublicId,
      pinnedItemPublicId: widget.task.pinnedItemPublicId,
    );
    _controller = TextEditingController()..addListener(() => _cubit.draftChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
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
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(labelText: AppStrings.writeEssayTextFieldLabel),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              WordCountLabel(minWordCount: widget.task.minWordCount, maxWordCount: widget.task.maxWordCount),
            ],
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
