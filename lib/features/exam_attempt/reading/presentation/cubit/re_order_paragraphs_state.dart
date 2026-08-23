import 'package:equatable/equatable.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

class ReOrderParagraphsState extends Equatable {
  const ReOrderParagraphsState({required this.currentOrder});

  /// The paragraphs in the student's current arrangement. `TaskOption.text`
  /// is a paragraph's full text; `TaskOption.orderIndex` is its stable
  /// correct-position identity — **never** its current index in this list,
  /// which is exactly what the student is rearranging.
  final List<TaskOption> currentOrder;

  @override
  List<Object?> get props => [currentOrder];
}
