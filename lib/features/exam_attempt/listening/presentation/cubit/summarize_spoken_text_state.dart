import 'package:equatable/equatable.dart';

class SummarizeSpokenTextState extends Equatable {
  const SummarizeSpokenTextState({this.draftText = '', this.wordCount = 0, this.hasFinishedPlaying = false, this.progress = 0.0});

  final String draftText;
  final int wordCount;
  final bool hasFinishedPlaying;
  final double progress;

  SummarizeSpokenTextState copyWith({String? draftText, int? wordCount, bool? hasFinishedPlaying, double? progress}) {
    return SummarizeSpokenTextState(
      draftText: draftText ?? this.draftText,
      wordCount: wordCount ?? this.wordCount,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [draftText, wordCount, hasFinishedPlaying, progress];
}
