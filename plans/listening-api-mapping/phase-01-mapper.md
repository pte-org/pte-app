# Phase 1: Mapper Implementation

**Stories Covered:**
- [P1] Multiple Choice mapping
- [P1] Matching parsing (Regex)

## 1. Data Model Setup
- Check if `lib/features/listening/data/models/question.dart` exists.
- If not, create it.
- **Fields:** `String id`, `int part`, `String questionType`, `String content`, `List<String> options`, `List<String> correctAnswers`.

## 2. Implement `ListeningQuestionMapper`
- Path: `lib/features/listening/domain/mappers/listening_question_mapper.dart`
- Create static method `mapToMultipleChoice(Question q)`.
  - Splits `q.content` by `\n` to support multiple questions inside one part (Part 3).
  - Divides `q.options` evenly.
  - Returns a list of UI-compatible models (e.g., `MockQuestion` equivalent).
- Create static method `mapToMatching(Question q)`.
  - Uses `RegExp(r'\[Blank\s*\d+\]')` to split `q.content`.
  - Extracts the labels (text before the blanks).
  - Divides `q.options` evenly by the number of blanks.
  - Returns a UI-compatible model (e.g., `MockMatchingQuestion` equivalent).
