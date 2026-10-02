import 'package:equatable/equatable.dart';

class McListeningMultipleState extends Equatable {
  const McListeningMultipleState({this.selectedOrderIndexes = const {}, this.hasFinishedPlaying = false, this.progress = 0.0, this.hasStartedPlaying = true});

  final Set<String> selectedOrderIndexes;
  final bool hasFinishedPlaying;
  final double progress;
  final bool hasStartedPlaying;

  McListeningMultipleState copyWith({Set<String>? selectedOrderIndexes, bool? hasFinishedPlaying, double? progress, bool? hasStartedPlaying}) {
    return McListeningMultipleState(
      selectedOrderIndexes: selectedOrderIndexes ?? this.selectedOrderIndexes,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
      hasStartedPlaying: hasStartedPlaying ?? this.hasStartedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndexes, hasFinishedPlaying, progress, hasStartedPlaying];
}
