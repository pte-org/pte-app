import 'package:equatable/equatable.dart';

class SummarizeSpokenTextState extends Equatable {
  const SummarizeSpokenTextState({this.draftText = '', this.wordCount = 0, this.hasFinishedPlaying = false});

  final String draftText;
  final int wordCount;
  final bool hasFinishedPlaying;

  SummarizeSpokenTextState copyWith({String? draftText, int? wordCount, bool? hasFinishedPlaying}) {
    return SummarizeSpokenTextState(
      draftText: draftText ?? this.draftText,
      wordCount: wordCount ?? this.wordCount,
      hasFinishedPlaying: hasFinishedPlaying ?? this.hasFinishedPlaying,
    );
  }

  @override
  List<Object?> get props => [draftText, wordCount, hasFinishedPlaying];
}
