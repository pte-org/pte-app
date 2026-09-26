import 'package:equatable/equatable.dart';

class SelectMissingWordState extends Equatable {
  const SelectMissingWordState({this.selectedOrderIndex, this.hasFinishedPlaying = false, this.progress = 0.0});

  final String? selectedOrderIndex;
  final bool hasFinishedPlaying;
  final double progress;

  SelectMissingWordState copyWith({String? selectedOrderIndex, bool? hasFinishedPlaying, double? progress}) {
    return SelectMissingWordState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndex, hasFinishedPlaying, progress];
}
