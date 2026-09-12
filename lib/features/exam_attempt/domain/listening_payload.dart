import 'package:pte_app/features/exam_attempt/domain/positional_payload.dart';

/// Serializes a Listening free-text answer without normalization.
String listeningFreeTextPayload(String draftText) => draftText;

/// Serializes a single Listening option selection.
///
/// An empty string remains valid for an unanswered task flushed by the local
/// exam timer; selected answers contain exactly one decimal orderIndex.
String listeningSingleSelectionPayload(String orderIndex) => orderIndex;

/// Serializes selected Listening option orderIndexes in numeric order.
String listeningMultipleSelectionPayload(Iterable<String> orderIndexes) {
  final sorted = orderIndexes.toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  return sorted.join(',');
}

/// Serializes typed Listening gap values in gap-index order.
///
/// Commas are reserved for positional separation by contract version 1. The
/// Listening gap input widget rejects them before this helper is called; the
/// guard here also protects non-UI callers from producing ambiguous payloads.
String listeningPositionalTextPayload(Iterable<String?> values) {
  final normalized = values.map((value) => value ?? '').toList();
  final invalidValue = normalized
      .where((value) => value.contains(','))
      .firstOrNull;
  if (invalidValue != null) {
    throw ArgumentError.value(
      invalidValue,
      'values',
      'Listening gap values must not contain commas in contract version 1',
    );
  }
  return positionalPayload(normalized);
}

/// Serializes selected transcript token positions in numeric order.
String listeningTranscriptWordIndicesPayload(Iterable<int> wordIndices) {
  final sorted = wordIndices.toList()..sort();
  return sorted.join(',');
}
