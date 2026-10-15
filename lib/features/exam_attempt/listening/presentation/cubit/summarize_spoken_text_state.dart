import 'package:equatable/equatable.dart';

class SummarizeSpokenTextState extends Equatable {
  const SummarizeSpokenTextState({this.draftText = '', this.wordCount = 0, this.hasFinishedPlaying = false, this.playbackFailed = false, this.progress = 0.0});

  final String draftText;
  final int wordCount;
  final bool hasFinishedPlaying;

  /// The audio could not be loaded or played. The student must not be stuck
  /// waiting for a "finished" signal that will never come.
  final bool playbackFailed;
  final double progress;

  SummarizeSpokenTextState copyWith({String? draftText, int? wordCount, bool? hasFinishedPlaying, bool? playbackFailed, double? progress}) {
    return SummarizeSpokenTextState(
      draftText: draftText ?? this.draftText,
      wordCount: wordCount ?? this.wordCount,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
      playbackFailed: playbackFailed ?? this.playbackFailed,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [draftText, wordCount, hasFinishedPlaying, playbackFailed, progress];
}
