# Brainstorm Report: Listening API Data Mapping
**Date:** 2026-07-03
**Topic:** How to map the API `Question` entity (V4 Flat Model) to the Flutter Listening UI templates (`ListeningMultipleChoicePage` & `ListeningMatchingPage`).

## What we explored
- The UI currently expects heavily structured data (Labels separate from Options, sub-instructions, etc.).
- The Backend V4 architecture removed nested entities (`QuestionOption` and `Passage`). Everything is flat: `content` (String), `options` (Array), and `correctAnswers` (Array).
- We discussed how to map this flat data to the two UI templates.

## Decisions Made
1. **Routing by Part & Question Type:** The UI will route the rendering logic entirely based on the `part` number.
   - `part == 1 || part == 3` ➔ Render `ListeningMultipleChoicePage`.
   - `part == 2 || part == 4` ➔ Render `ListeningMatchingPage`.
2. **Handling Matching Labels (Option A chosen):**
   - For Matching parts (2 & 4), the API will utilize the `[Blank X]` syntax inside the `content` field.
   - The text preceding `[Blank X]` will be treated as the **Label** (e.g., "Speaker A wants to").
   - The `options` array will supply the dropdown choices (divided evenly among the number of blanks, per V4 spec).

## What’s Next
- Proceed with `/ck-plan` or `/ck-cook` to implement the `ListeningQuestionMapper` in Flutter, which will parse the `[Blank X]` tags and adapt the `Question` model into the format expected by the UI widgets.
