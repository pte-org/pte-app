import '../../domain/repositories/session_entry_repository.dart';

/// Mutable holder for the raw text a student typed, written by
/// `SessionEntryPage` just before dispatching `SessionResolutionRequested`
/// — decouples the long-lived, DI-managed [ManualSessionEntryRepository]
/// from any single widget's `TextEditingController` lifecycle.
class SessionIdInputBuffer {
  String value = '';
}

/// Placeholder implementation: a plain manual-text-entry screen reads the
/// raw input via [readInput] (backed by a [SessionIdInputBuffer] the UI
/// layer writes into, so this class never holds a `BuildContext` or a
/// Flutter widget dependency). Kept deliberately dumb — no
/// attempt-lifecycle logic belongs here, only input validation, per
/// phase-03 Design Constraints.
class ManualSessionEntryRepository implements SessionEntryRepository {
  ManualSessionEntryRepository({required String Function() readInput}) : _readInput = readInput;

  final String Function() _readInput;

  @override
  Future<String> resolveSessionPublicId() async {
    final raw = _readInput().trim();
    if (raw.isEmpty) {
      throw const SessionResolutionException('Session ID cannot be empty.');
    }
    return raw;
  }
}
