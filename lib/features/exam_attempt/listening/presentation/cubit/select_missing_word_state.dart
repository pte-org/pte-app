import 'package:equatable/equatable.dart';

class SelectMissingWordState extends Equatable {
  const SelectMissingWordState({this.selectedOrderIndex, this.hasFinishedPlaying = false});

  final String? selectedOrderIndex;
  final bool hasFinishedPlaying;

  SelectMissingWordState copyWith({String? selectedOrderIndex, bool? hasFinishedPlaying}) {
    return SelectMissingWordState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedOrderIndex, hasFinishedPlaying];
}
