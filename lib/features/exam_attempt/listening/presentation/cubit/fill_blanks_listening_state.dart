import 'package:equatable/equatable.dart';

class FillBlanksListeningState extends Equatable {
  const FillBlanksListeningState({required this.answers, this.hasFinishedPlaying = false});

  /// Fixed-length list (length = number of `{{n}}` markers), index-aligned
  /// to gap index — free-typed text per gap, `''` for unanswered.
  final List<String> answers;

  final bool hasFinishedPlaying;

  FillBlanksListeningState copyWith({List<String>? answers, bool? hasFinishedPlaying}) {
    return FillBlanksListeningState(
      answers: answers ?? this.answers,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [answers, hasFinishedPlaying];
}
