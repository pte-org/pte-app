import 'package:equatable/equatable.dart';

class McReadingMultipleState extends Equatable {
  const McReadingMultipleState({this.selectedOrderIndexes = const {}});

  /// The currently-checked options' `orderIndex` values (decimal strings) —
  /// the same values written verbatim as the outbox payload (sorted at
  /// write time, not here), never list positions.
  final Set<String> selectedOrderIndexes;

  McReadingMultipleState copyWith({Set<String>? selectedOrderIndexes}) {
    return McReadingMultipleState(selectedOrderIndexes: selectedOrderIndexes ?? this.selectedOrderIndexes);
  }

  @override
  List<Object?> get props => [selectedOrderIndexes];
}
