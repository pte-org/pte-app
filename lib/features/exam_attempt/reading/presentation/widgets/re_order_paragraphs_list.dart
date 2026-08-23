import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_state.dart';

/// Draggable paragraph list — items keyed by `orderIndex` (stable identity,
/// never on-screen position). Each tile carries a `Semantics` label
/// reflecting its current position for accessibility.
class ReOrderParagraphsList extends StatelessWidget {
  const ReOrderParagraphsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReOrderParagraphsCubit, ReOrderParagraphsState>(
      builder: (context, state) {
        final paragraphs = state.currentOrder;
        return ReorderableListView(
          // `ReorderableListView.onReorder` reports `newIndex` as the
          // insertion point *before* the dragged item is removed from
          // `oldIndex` — moving an item forward always overstates the final
          // index by one, so the classic adjustment below is required (this
          // is `onReorder`'s actual, only contract; there is no
          // `onReorderItem` parameter in Flutter's `ReorderableListView`).
          // `ReOrderParagraphsCubit.reorder` expects the already-adjusted
          // final resting index.
          onReorder: (oldIndex, newIndex) {
            final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
            context.read<ReOrderParagraphsCubit>().reorder(oldIndex, adjustedNewIndex);
          },
          children: [
            for (var position = 0; position < paragraphs.length; position++)
              Semantics(
                key: ValueKey(paragraphs[position].orderIndex),
                label: 'Paragraph, position ${position + 1} of ${paragraphs.length}, draggable',
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMedium,
                    vertical: AppDimensions.spacingMedium / 2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingMedium),
                    child: Text(paragraphs[position].text),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
