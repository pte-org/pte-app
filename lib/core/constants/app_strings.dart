/// User-facing strings. No `Text('literal')` anywhere in the app — every
/// label goes through this class per `docs/CODING_STANDARDS_APP.md`.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'PTE Student';

  static const String sessionEntryTitle = 'Enter session ID';
  static const String sessionEntryFieldLabel = 'Session ID';
  static const String sessionEntryStartButton = 'Start';

  static const String examPhasePrepLabel = 'Preparation';
  static const String examPhaseResponseLabel = 'Response';
  static const String examTaskCounterOf = ' / ';

  static const String taskAdvanceButtonLabel = 'Next';
  static const String writeEssayTextFieldLabel = 'Your response';
  static const String wordCountSuffix = ' words';
  static const String wordCountBoundsOpen = ' (';
  static const String wordCountMinLabel = 'min ';
  static const String wordCountMaxLabel = 'max ';
  static const String wordCountBoundsSeparator = ', ';
  static const String wordCountBoundsClose = ')';
  static const String unsupportedTaskTypePrefix = 'Unsupported task type: ';
}
