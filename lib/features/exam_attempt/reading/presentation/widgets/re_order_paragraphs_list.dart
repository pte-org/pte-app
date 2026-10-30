import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/re_order_paragraphs_cubit.dart';
import '../cubit/re_order_paragraphs_state.dart';
import 'paragraph_source_target.dart';

class ReOrderParagraphsList extends StatelessWidget {
  const ReOrderParagraphsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReOrderParagraphsCubit, ReOrderParagraphsState>(
      builder: (context, state) {
        final cubit = context.read<ReOrderParagraphsCubit>();
        return ParagraphSourceTarget(
          paragraphs: {
            for (final option in cubit.paragraphs)
              option.orderIndex: option.text,
          },
          targetIds: [
            for (final option in state.currentOrder) option.orderIndex,
          ],
          onChanged: cubit.setTargetOrder,
        );
      },
    );
  }
}
