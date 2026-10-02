import 'package:equatable/equatable.dart';

class SummarizeSpokenTextState extends Equatable {
  const SummarizeSpokenTextState({this.draftText = '', this.wordCount = 0, this.hasFinishedPlaying = false, this.progress = 0.0, this.hasStartedPlaying = true});

  final String draftText;
  final int wordCount;
  final bool hasFinishedPlaying;
  final double progress;
  final bool hasStartedPlaying;

  SummarizeSpokenTextState copyWith({String? draftText, int? wordCount, bool? hasFinishedPlaying, double? progress, bool? hasStartedPlaying}) {
    return SummarizeSpokenTextState(
      draftText: draftText ?? this.draftText,
      wordCount: wordCount ?? this.wordCount,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
      hasStartedPlaying: hasStartedPlaying ?? this.hasStartedPlaying,
    );
  }

  @override
  List<Object?> get props => [draftText, wordCount, hasFinishedPlaying, progress, hasStartedPlaying];
}
