import 'package:equatable/equatable.dart';

class McListeningMultipleState extends Equatable {
  const McListeningMultipleState({this.selectedOrderIndexes = const {}, this.hasFinishedPlaying = false, this.progress = 0.0});

  final Set<String> selectedOrderIndexes;
  final bool hasFinishedPlaying;
  final double progress;

  McListeningMultipleState copyWith({Set<String>? selectedOrderIndexes, bool? hasFinishedPlaying, double? progress}) {
    return McListeningMultipleState(
      selectedOrderIndexes: selectedOrderIndexes ?? this.selectedOrderIndexes,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndexes, hasFinishedPlaying, progress];
}
