import 'package:equatable/equatable.dart';

class WriteEssayState extends Equatable {
  const WriteEssayState({this.draftText = ''});

  /// Raw typed text, untouched — no trimming/normalization beyond whatever
  /// the `TextEditingController` already holds (phase-05 Design
  /// Constraints).
  final String draftText;

  WriteEssayState copyWith({String? draftText}) => WriteEssayState(draftText: draftText ?? this.draftText);

  @override
  List<Object?> get props => [draftText];
}
