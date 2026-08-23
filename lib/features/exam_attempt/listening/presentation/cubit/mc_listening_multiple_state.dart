import 'package:equatable/equatable.dart';

class McListeningMultipleState extends Equatable {
  const McListeningMultipleState({this.selectedOrderIndexes = const {}, this.hasFinishedPlaying = false});

  final Set<String> selectedOrderIndexes;
  final bool hasFinishedPlaying;

  McListeningMultipleState copyWith({Set<String>? selectedOrderIndexes, bool? hasFinishedPlaying}) {
    return McListeningMultipleState(
      selectedOrderIndexes: selectedOrderIndexes ?? this.selectedOrderIndexes,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndexes, hasFinishedPlaying];
}
