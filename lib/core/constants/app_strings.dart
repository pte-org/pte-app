/// Truly global user-facing strings (app shell only) — feature-specific
/// strings live in each feature's own `constants/` file (e.g.
/// `ExamAttemptStrings`, `ReadingStrings`, `ListeningStrings`,
/// `SpeakingWritingStrings`, `ReportStrings`) so this file doesn't grow
/// unbounded as task types are added. No `Text('literal')` anywhere in the
/// app — every label goes through one of these classes per
/// `docs/CODING_STANDARDS_APP.md`.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'PTE Student';
}
