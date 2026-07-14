# Brainstorm Report: Listening Test Runner
**Date:** 2026-07-03
**Topic:** Stitching the 4 Listening parts into a cohesive, navigable exam flow.

## What we explored
- The requirement is to connect the 4 Listening parts together so the user can navigate through them using the "Next" and "Back" buttons in the `ExamScaffold`.
- The current implementation has individual pages (`ListeningMultipleChoicePage` and `ListeningMatchingPage`) that are isolated and don't preserve user answers if they navigate away and come back.
- We discussed where to store the answer state to ensure answers are preserved during navigation.

## Decisions Made
1. **Retain 4-Part Structure:** We will NOT delete the Matching code. The system will continue to support 4 parts (Part 1/3 Multiple Choice, Part 2/4 Matching).
2. **Test Runner Architecture:** We will create a `ListeningTestRunnerPage` which acts as the orchestrator. It will:
   - Hold an array of 4 mock questions (one for each part).
   - Maintain the `_currentIndex` to track which part the user is currently on.
   - Render the appropriate child page (`ListeningMultipleChoicePage` or `ListeningMatchingPage`) based on the current question's part.
3. **State Management Hoisting:** To prevent answer loss upon navigation, the `ListeningTestRunnerPage` will store the answers. The child pages will receive their initial state from the Runner and use an `onAnswerSelected` callback to notify the Runner of any changes.

## What’s Next
- Proceed with `/ck-plan` or `/ck-cook` to implement the `ListeningTestRunnerPage` and update the child pages to support callbacks.
