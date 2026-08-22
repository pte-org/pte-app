import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../domain/blank_prompt_parser.dart';
import '../../domain/task_view.dart';
import '../cubit/fill_blanks_dropdown_cubit.dart';
import '../cubit/fill_blanks_dropdown_state.dart';

/// Passage with inline per-gap dropdowns — each gap's items come strictly
/// from its own `BlankGroup.options`, never a shared list. Requires
/// `task.blankGroups` to be non-null/non-empty; the caller (the screen)
/// renders the `StatusBanner` fallback instead when it isn't.
class FillBlanksDropdownBody extends StatelessWidget {
  const FillBlanksDropdownBody({super.key, required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    final blankGroups = task.blankGroups!;
    final segments = parseBlankPrompt(task.promptText ?? '');

    return BlocBuilder<FillBlanksDropdownCubit, FillBlanksDropdownState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Text.rich(
            TextSpan(children: [for (final segment in segments) _spanFor(context, segment, blankGroups, state)]),
          ),
        );
      },
    );
  }

  InlineSpan _spanFor(
    BuildContext context,
    PromptSegment segment,
    List<BlankGroup> blankGroups,
    FillBlanksDropdownState state,
  ) {
    if (segment is PromptTextSegment) {
      return TextSpan(text: segment.text);
    }
    final gapIndex = (segment as PromptGapSegment).gapIndex;
    final group = blankGroups.firstWhere((g) => g.blankIndex == gapIndex);
    final selected = state.selectedOrderIndexes[gapIndex];
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Semantics(
        label: selected == null
            ? 'Gap ${gapIndex + 1}, empty'
            : 'Gap ${gapIndex + 1}, filled with '
                  '\'${group.options.firstWhere((o) => o.orderIndex == selected).text}\'',
        child: DropdownButton<String>(
          value: selected,
          items: [
            for (final option in group.options) DropdownMenuItem(value: option.orderIndex, child: Text(option.text)),
          ],
          onChanged: (value) {
            if (value != null) context.read<FillBlanksDropdownCubit>().selectOption(gapIndex, value);
          },
        ),
      ),
    );
  }
}
