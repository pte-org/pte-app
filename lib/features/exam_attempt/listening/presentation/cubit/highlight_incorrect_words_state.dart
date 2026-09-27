import 'package:equatable/equatable.dart';

class HighlightIncorrectWordsState extends Equatable {
  const HighlightIncorrectWordsState({this.selectedWordIndices = const {}, this.hasFinishedPlaying = false, this.progress = 0.0, this.hasStartedPlaying = true});

  final Set<int> selectedWordIndices;
  final bool hasFinishedPlaying;
  final double progress;
  final bool hasStartedPlaying;

  HighlightIncorrectWordsState copyWith({Set<int>? selectedWordIndices, bool? hasFinishedPlaying, double? progress, bool? hasStartedPlaying}) {
    return HighlightIncorrectWordsState(
      selectedWordIndices: selectedWordIndices ?? this.selectedWordIndices,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
      hasStartedPlaying: hasStartedPlaying ?? this.hasStartedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedWordIndices, hasFinishedPlaying, progress, hasStartedPlaying];
}
