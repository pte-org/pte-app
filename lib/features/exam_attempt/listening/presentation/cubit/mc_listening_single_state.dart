import 'package:equatable/equatable.dart';

class McListeningSingleState extends Equatable {
  const McListeningSingleState({this.selectedOrderIndex, this.hasFinishedPlaying = false});

  final String? selectedOrderIndex;
  final bool hasFinishedPlaying;

  McListeningSingleState copyWith({String? selectedOrderIndex, bool? hasFinishedPlaying}) {
    return McListeningSingleState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndex, hasFinishedPlaying];
}
