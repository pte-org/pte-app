import 'package:equatable/equatable.dart';

class HighlightIncorrectWordsState extends Equatable {
  const HighlightIncorrectWordsState({this.selectedWordIndices = const {}, this.hasFinishedPlaying = false, this.progress = 0.0});

  final Set<int> selectedWordIndices;
  final bool hasFinishedPlaying;
  final double progress;

  HighlightIncorrectWordsState copyWith({Set<int>? selectedWordIndices, bool? hasFinishedPlaying, double? progress}) {
    return HighlightIncorrectWordsState(
      selectedWordIndices: selectedWordIndices ?? this.selectedWordIndices,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [selectedWordIndices, hasFinishedPlaying, progress];
}
