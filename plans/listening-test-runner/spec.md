# Spec: Listening Test Runner

**Date:** 2026-07-03
**Status:** Ready

---

## Problem Statement
Currently, the Listening test pages (`ListeningMultipleChoicePage` and `ListeningMatchingPage`) exist in isolation. There is no orchestrator to flow from one part to the next, and navigating away destroys local widget state (losing selected answers). A Test Runner is needed to manage the sequence and persist state across navigations.

---

## User Stories

- **[P1]** As a student taking the Listening test, I want to click the "Next" button on the bottom bar to proceed to the next part of the exam.
  Accepted when: Clicking "Next" increments the index and loads the next question without reloading the entire app.

- **[P1]** As a student, I want to be able to click "Back" to review my previous answers, and they should still be filled in.
  Accepted when: The Test Runner preserves answer states and passes them down to the UI upon returning to a previous question.

---

## Functional Requirements

1. **FR-01 (Runner Component):** Create `ListeningTestRunnerPage` (StatefulWidget) that manages `List<Question>` and an `int _currentIndex`.
2. **FR-02 (Routing):** The `build()` method of the runner must check `questions[_currentIndex].part` and render either `ListeningMultipleChoicePage` or `ListeningMatchingPage`.
3. **FR-03 (Navigation Callbacks):** The Runner passes `onNext` and `onBack` functions to the child pages.
4. **FR-04 (Scaffold Integration):** The child pages pass these callbacks into their internal `ExamScaffold`'s `onNext` and `onBack` properties.
5. **FR-05 (Answer Preservation):** The Runner maintains a `Map<String, dynamic> _answers` state. Child pages receive their specific answers via props and update the Runner via an `onAnswerUpdate(dynamic answer)` callback.

---

## Non-Functional Requirements
- Maintainability: The `ExamScaffold` should not be re-rendered violently; page transitions should feel smooth.

---

## Success Criteria
- [ ] A user can navigate seamlessly from Part 1 to Part 4 using the Next button.
- [ ] A user can navigate backwards and see their previous selections intact.

---

## Out of Scope
- Submitting the final answers to the Backend (we only focus on UI flow and local state retention for now).
