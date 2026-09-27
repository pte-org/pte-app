import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Decodes the stable payload formats written by the task cubits so a task
/// can be reconstructed from its local outbox row when the candidate returns.
String? singleSelectionFromAnswerPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  return payload;
}

Set<String> optionIndexesFromAnswerPayload(String? payload) {
  if (payload == null || payload.isEmpty) return const {};
  return payload.split(',').where((value) => value.isNotEmpty).toSet();
}

Set<int> indicesFromAnswerPayload(String? payload) {
  if (payload == null || payload.isEmpty) return const {};
  return payload
      .split(',')
      .map(int.tryParse)
      .whereType<int>()
      .where((index) => index >= 0)
      .toSet();
}

List<String> positionalValuesFromAnswerPayload(
  String? payload, {
  required int length,
}) {
  if (length <= 0) return const [];
  final values = payload == null ? const <String>[] : payload.split(',');
  return List.generate(
    length,
    (index) => index < values.length ? values[index] : '',
  );
}

List<String?> positionalSelectionsFromAnswerPayload(
  String? payload, {
  required int length,
}) {
  return positionalValuesFromAnswerPayload(
    payload,
    length: length,
  ).map((value) => value.isEmpty ? null : value).toList(growable: false);
}

List<TaskOption> reorderedOptionsFromAnswerPayload({
  required List<TaskOption> defaultOrder,
  required String? payload,
}) {
  if (payload == null || payload.isEmpty || defaultOrder.isEmpty) {
    return defaultOrder;
  }

  final byOrderIndex = {
    for (final option in defaultOrder) option.orderIndex: option,
  };
  final restoredIndexes = payload.split(',');
  if (restoredIndexes.length != defaultOrder.length ||
      restoredIndexes.toSet().length != defaultOrder.length ||
      restoredIndexes.any((index) => !byOrderIndex.containsKey(index))) {
    return defaultOrder;
  }
  return restoredIndexes
      .map((index) => byOrderIndex[index]!)
      .toList(growable: false);
}

Map<int, TaskOption> gapAssignmentsFromAnswerPayload({
  required String? payload,
  required int gapCount,
  required List<TaskOption> options,
}) {
  final values = positionalValuesFromAnswerPayload(payload, length: gapCount);
  final byOrderIndex = {
    for (final option in options) option.orderIndex: option,
  };
  final assignments = <int, TaskOption>{};
  final usedOptions = <String>{};
  for (var gapIndex = 0; gapIndex < values.length; gapIndex++) {
    final orderIndex = values[gapIndex];
    final option = byOrderIndex[orderIndex];
    if (option == null || !usedOptions.add(orderIndex)) continue;
    assignments[gapIndex] = option;
  }
  return assignments;
}
