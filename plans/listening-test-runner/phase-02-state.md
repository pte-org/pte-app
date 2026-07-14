# Phase 2: Page Integration & State Hoisting

**Stories Covered:**
- [P1] Preserve answers across navigation

## 1. Update `ListeningMultipleChoicePage`
- Add props: `onNext`, `onBack`, `initialAnswers`, `onAnswersChanged`.
- Initialize `_selectedIndices` using `initialAnswers`.
- Trigger `onAnswersChanged` whenever an option is selected.
- Connect `onNext` and `onBack` to `ExamScaffold`.

## 2. Update `ListeningMatchingPage`
- Add props: `onNext`, `onBack`, `initialAnswers`, `onAnswersChanged`.
- Initialize `_selectedValues` using `initialAnswers`.
- Trigger `onAnswersChanged` whenever a dropdown changes.
- Connect `onNext` and `onBack` to `ExamScaffold`.

## 3. Update `app.dart`
- Point home to `ListeningTestRunnerPage()`.
