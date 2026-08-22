import 'package:equatable/equatable.dart';

class HighlightIncorrectWordsState extends Equatable {
  const HighlightIncorrectWordsState({this.selectedWordIndices = const {}, this.hasFinishedPlaying = false});

  final Set<int> selectedWordIndices;
  final bool hasFinishedPlaying;

  HighlightIncorrectWordsState copyWith({Set<int>? selectedWordIndices, bool? hasFinishedPlaying}) {
    return HighlightIncorrectWordsState(
      selectedWordIndices: selectedWordIndices ?? this.selectedWordIndices,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedWordIndices, hasFinishedPlaying];
}
