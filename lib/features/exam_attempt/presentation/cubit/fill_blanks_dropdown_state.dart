import 'package:equatable/equatable.dart';

class FillBlanksDropdownState extends Equatable {
  const FillBlanksDropdownState({required this.selectedOrderIndexes});

  /// Fixed-length list (length = `blankGroups.length`), index-aligned to
  /// gap index — each entry is the selected option's `orderIndex` from
  /// that gap's own `BlankGroup.options`, or `null` if unanswered.
  final List<String?> selectedOrderIndexes;

  FillBlanksDropdownState copyWith({List<String?>? selectedOrderIndexes}) {
    return FillBlanksDropdownState(selectedOrderIndexes: selectedOrderIndexes ?? this.selectedOrderIndexes);
  }

  @override
  List<Object?> get props => [selectedOrderIndexes];
}
