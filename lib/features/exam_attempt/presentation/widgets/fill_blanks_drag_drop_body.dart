import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/blank_prompt_parser.dart';
import '../../domain/task_view.dart';
import '../cubit/fill_blanks_drag_drop_cubit.dart';
import '../cubit/fill_blanks_drag_drop_state.dart';

/// Drag payload for both bank chips and placed gap words. [fromGapIndex] is
/// null for a bank chip and set for a word currently occupying a gap — the
/// bank-level drop target needs it to know which gap to clear on undo.
class _DraggedWord {
  const _DraggedWord({required this.option, this.fromGapIndex});

  final TaskOption option;
  final int? fromGapIndex;
}

/// Passage with inline drag-target gaps + a shared drag-source word bank
/// below. See `ninh-pte-reading-task-types` Phase 5 Design Constraints for
/// the full drop/undo/reassignment contract.
class FillBlanksDragDropBody extends StatelessWidget {
  const FillBlanksDragDropBody({super.key, required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    final bankOptions = task.options ?? const <TaskOption>[];
    final segments = parseBlankPrompt(task.promptText ?? '');

    return BlocBuilder<FillBlanksDragDropCubit, FillBlanksDragDropState>(
      builder: (context, state) {
        final cubit = context.read<FillBlanksDragDropCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [for (final segment in segments) _spanFor(segment, state.gapAssignments)])),
              const SizedBox(height: AppDimensions.spacingMedium),
              Text(AppStrings.fillBlanksWordBankSectionLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppDimensions.spacingMedium / 2),
              _WordBank(bankOptions: bankOptions, gapAssignments: state.gapAssignments, cubit: cubit),
            ],
          ),
        );
      },
    );
  }

  InlineSpan _spanFor(PromptSegment segment, Map<int, TaskOption> gapAssignments) {
    if (segment is PromptTextSegment) {
      return TextSpan(text: segment.text);
    }
    final gapIndex = (segment as PromptGapSegment).gapIndex;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _GapTarget(gapIndex: gapIndex, assigned: gapAssignments[gapIndex]),
    );
  }
}

class _GapTarget extends StatelessWidget {
  const _GapTarget({required this.gapIndex, required this.assigned});

  final int gapIndex;
  final TaskOption? assigned;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DraggedWord>(
      onAcceptWithDetails: (details) =>
          context.read<FillBlanksDragDropCubit>().assignToGap(gapIndex, details.data.option),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final content = assigned == null
            ? Text(AppStrings.fillBlanksGapPlaceholder)
            : Text(assigned!.text, style: const TextStyle(fontWeight: FontWeight.bold));

        final gapBox = Container(
          constraints: const BoxConstraints(minWidth: AppDimensions.fillBlanksGapMinWidth),
          padding: const EdgeInsets.all(AppDimensions.fillBlanksGapPadding),
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.dragTargetHoverBackground
                : (assigned == null ? null : AppColors.fillBlanksGapFilledBackground),
            border: Border.all(color: AppColors.fillBlanksGapEmptyBorder),
          ),
          child: Center(child: content),
        );

        return Semantics(
          label: assigned == null ? 'Gap ${gapIndex + 1}, empty' : 'Gap ${gapIndex + 1}, filled with \'${assigned!.text}\'',
          child: assigned == null
              ? gapBox
              : Draggable<_DraggedWord>(
                  data: _DraggedWord(option: assigned!, fromGapIndex: gapIndex),
                  feedback: Material(color: Colors.transparent, child: gapBox),
                  childWhenDragging: Opacity(opacity: 0.3, child: gapBox),
                  child: gapBox,
                ),
        );
      },
    );
  }
}

class _WordBank extends StatelessWidget {
  const _WordBank({required this.bankOptions, required this.gapAssignments, required this.cubit});

  final List<TaskOption> bankOptions;
  final Map<int, TaskOption> gapAssignments;
  final FillBlanksDragDropCubit cubit;

  @override
  Widget build(BuildContext context) {
    // Always filtered from the original task.options order — never a
    // separately mutated/re-appended list — so an undone chip reappears at
    // its original bank position (phase-05 Design Constraints).
    final placedOrderIndexes = gapAssignments.values.map((o) => o.orderIndex).toSet();
    final available = bankOptions.where((option) => !placedOrderIndexes.contains(option.orderIndex));

    return DragTarget<_DraggedWord>(
      onAcceptWithDetails: (details) {
        final fromGapIndex = details.data.fromGapIndex;
        if (fromGapIndex != null) cubit.clearGap(fromGapIndex);
      },
      builder: (context, candidateData, rejectedData) {
        return Wrap(
          spacing: AppDimensions.dragChipSpacing,
          runSpacing: AppDimensions.dragChipSpacing,
          children: [
            for (final option in available)
              Semantics(
                label: 'Word chip \'${option.text}\', draggable',
                child: Draggable<_DraggedWord>(
                  data: _DraggedWord(option: option),
                  feedback: Material(color: Colors.transparent, child: _WordChip(option: option)),
                  childWhenDragging: Opacity(opacity: 0.3, child: _WordChip(option: option)),
                  child: _WordChip(option: option),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.option});

  final TaskOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.dragChipPadding),
      decoration: BoxDecoration(
        color: AppColors.dragChipBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Text(option.text),
    );
  }
}
