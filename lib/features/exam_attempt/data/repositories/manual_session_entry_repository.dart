import '../../domain/repositories/session_entry_repository.dart';

/// Placeholder implementation: `rawInput` is exactly what the student
/// typed into the manual text-entry field, passed straight through from
/// `SessionResolutionRequested` — this class never holds a
/// `BuildContext` or a `TextEditingController`. Kept deliberately dumb —
/// no attempt-lifecycle logic belongs here, only input validation, per
/// phase-03 Design Constraints.
class ManualSessionEntryRepository implements SessionEntryRepository {
  const ManualSessionEntryRepository();

  @override
  Future<String> resolveSessionPublicId(String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      throw const SessionResolutionException('Session ID cannot be empty.');
    }
    return trimmed;
  }
}
