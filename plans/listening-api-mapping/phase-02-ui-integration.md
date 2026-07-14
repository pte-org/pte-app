# Phase 2: UI Integration

**Stories Covered:**
- [P1] Render Multiple Choice
- [P1] Render Matching

## 1. Refactor `ListeningMultipleChoicePage`
- Change `MockQuestion` to the output type of the mapper, or directly accept `Question` and run the mapper in `initState()`.
- Update state variables to handle the new mapped data structure.

## 2. Refactor `ListeningMatchingPage`
- Change `MockMatchingQuestion` to directly accept `Question`.
- Run `ListeningQuestionMapper.mapToMatching` inside `initState()`.
- Update state variables.

## 3. Update `app.dart` Testing Route
- Construct a mock `Question` object conforming to the V4 spec (flat arrays, `[Blank X]` syntax).
- Pass it into the page to verify rendering works exactly as before.
