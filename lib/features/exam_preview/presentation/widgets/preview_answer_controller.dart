/// In-memory response store for a single host preview. It is intentionally
/// not a ChangeNotifier or persistence abstraction: the preview cubit owns its
/// lifetime and clears it on finish/logout/error.
class PreviewAnswerController {
  final Map<String, Object?> _answers = <String, Object?>{};

  Object? valueFor(String key) => _answers[key];

  void setValue(String key, Object? value) {
    if (value == null) {
      _answers.remove(key);
    } else {
      _answers[key] = value;
    }
  }

  void clearValue(String key) => _answers.remove(key);

  Map<String, Object?> snapshot() => Map.unmodifiable(_answers);

  void clear() => _answers.clear();
}
