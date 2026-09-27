import 'package:equatable/equatable.dart';

class McListeningSingleState extends Equatable {
  const McListeningSingleState({this.selectedOrderIndex, this.hasFinishedPlaying = false, this.progress = 0.0});

  final String? selectedOrderIndex;
  final bool hasFinishedPlaying;
  final double progress;

  McListeningSingleState copyWith({String? selectedOrderIndex, bool? hasFinishedPlaying, double? progress}) {
    return McListeningSingleState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndex, hasFinishedPlaying, progress];
}
