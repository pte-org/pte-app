import 'package:equatable/equatable.dart';

class FillBlanksListeningState extends Equatable {
  const FillBlanksListeningState({required this.answers, this.hasFinishedPlaying = false, this.progress = 0.0});

  /// Fixed-length list (length = number of `{{n}}` markers), index-aligned
  /// to gap index — free-typed text per gap, `''` for unanswered.
  final List<String> answers;

  final bool hasFinishedPlaying;
  final double progress;

  FillBlanksListeningState copyWith({List<String>? answers, bool? hasFinishedPlaying, double? progress}) {
    return FillBlanksListeningState(
      answers: answers ?? this.answers,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [answers, hasFinishedPlaying, progress];
}
