import 'package:equatable/equatable.dart';

import '../../domain/task_view.dart';

class FillBlanksDragDropState extends Equatable {
  const FillBlanksDragDropState({this.gapAssignments = const {}});

  /// gapIndex -> the word currently placed there. A gap with no entry is
  /// unfilled. Values come from the shared word bank (`TaskView.options`);
  /// `TaskOption.orderIndex` is each word's stable identity.
  final Map<int, TaskOption> gapAssignments;

  FillBlanksDragDropState copyWith({Map<int, TaskOption>? gapAssignments}) {
    return FillBlanksDragDropState(gapAssignments: gapAssignments ?? this.gapAssignments);
  }

  @override
  List<Object?> get props => [gapAssignments];
}
