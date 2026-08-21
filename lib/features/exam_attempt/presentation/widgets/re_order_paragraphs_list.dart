import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../cubit/re_order_paragraphs_cubit.dart';
import '../cubit/re_order_paragraphs_state.dart';

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
          onReorderItem: (oldIndex, newIndex) => context.read<ReOrderParagraphsCubit>().reorder(oldIndex, newIndex),
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
