import 'package:equatable/equatable.dart';

class HighlightCorrectSummaryState extends Equatable {
  const HighlightCorrectSummaryState({this.selectedOrderIndex, this.hasFinishedPlaying = false, this.progress = 0.0, this.hasStartedPlaying = true});

  final String? selectedOrderIndex;
  final bool hasFinishedPlaying;
  final double progress;
  final bool hasStartedPlaying;

  HighlightCorrectSummaryState copyWith({String? selectedOrderIndex, bool? hasFinishedPlaying, double? progress, bool? hasStartedPlaying}) {
    return HighlightCorrectSummaryState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
      hasStartedPlaying: hasStartedPlaying ?? this.hasStartedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndex, hasFinishedPlaying, progress, hasStartedPlaying];
}
