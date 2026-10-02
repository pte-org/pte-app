import 'package:equatable/equatable.dart';

class WriteFromDictationState extends Equatable {
  const WriteFromDictationState({this.draftText = '', this.wordCount = 0, this.hasFinishedPlaying = false, this.progress = 0.0, this.hasStartedPlaying = true});

  final String draftText;
  final int wordCount;

  /// Drives [ListeningAudioBar]'s locked/unlocked visual — flips to `true`
  /// exactly once, when [AudioPlayerService.hasFinishedPlaying] fires
  /// (phase-01 Design Constraints: no replay, so this never resets).
  final bool hasFinishedPlaying;
  final double progress;
  final bool hasStartedPlaying;

  WriteFromDictationState copyWith({String? draftText, int? wordCount, bool? hasFinishedPlaying, double? progress, bool? hasStartedPlaying}) {
    return WriteFromDictationState(
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
