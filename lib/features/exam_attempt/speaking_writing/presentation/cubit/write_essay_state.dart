import 'package:equatable/equatable.dart';

class WriteEssayState extends Equatable {
  const WriteEssayState({this.draftText = '', this.wordCount = 0});

  /// Raw typed text, untouched — no trimming/normalization beyond whatever
  /// the `TextEditingController` already holds (phase-05 Design
  /// Constraints).
  final String draftText;

  /// Computed once per [draftText] change by `WriteEssayCubit.draftChanged`
  /// (not re-derived by every `BlocSelector` evaluation) so a widget
  /// selecting only this int avoids rerunning `countWords`'s regex split
  /// on every keystroke just to discover the value hasn't changed.
  final int wordCount;

  WriteEssayState copyWith({String? draftText, int? wordCount}) {
    return WriteEssayState(draftText: draftText ?? this.draftText, wordCount: wordCount ?? this.wordCount);
  }

  @override
  List<Object?> get props => [draftText, wordCount];
}
