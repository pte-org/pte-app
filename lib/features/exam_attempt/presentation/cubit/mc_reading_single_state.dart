import 'package:equatable/equatable.dart';

class McReadingSingleState extends Equatable {
  const McReadingSingleState({this.selectedOrderIndex});

  /// The selected option's `orderIndex` (decimal string, e.g. `"2"`) — the
  /// same value written verbatim as the outbox payload, never the list
  /// position (phase-05 Design Constraints).
  final String? selectedOrderIndex;

  McReadingSingleState copyWith({String? selectedOrderIndex}) {
    return McReadingSingleState(selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex);
  }

  @override
  List<Object?> get props => [selectedOrderIndex];
}
