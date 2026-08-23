import 'package:equatable/equatable.dart';

class HighlightCorrectSummaryState extends Equatable {
  const HighlightCorrectSummaryState({this.selectedOrderIndex, this.hasFinishedPlaying = false});

  final String? selectedOrderIndex;
  final bool hasFinishedPlaying;

  HighlightCorrectSummaryState copyWith({String? selectedOrderIndex, bool? hasFinishedPlaying}) {
    return HighlightCorrectSummaryState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndex, hasFinishedPlaying];
}
