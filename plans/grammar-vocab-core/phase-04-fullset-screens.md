# Phase 4 — Q27/Q30 screens + grid variant + reference fidelity

**Covers:** R2 P1 (Q27, Q30) · R2 P2 (no example row) · **Depends on:** none
**Testing:** default

> **Scope update (2026-07-03):** **Q29 dropped** (same synonym layout as Q26). Build only Q27 + Q30.

---

## Outcome

The two missing Grammar & Vocab match screens (Q27, Q30) exist and match their screenshots, built
by **reusing one generic word-match page** over the existing `WordMatchingGrid`. Q26/Q30 render
5 plain rows (no "Example", no `=`); Q27 uses a left-aligned wrapping variant.

## Key decision (DRY)

Q26, Q27, Q30 are the **same** "label → dropdown" layout with different instruction + data.
Do **not** write separate page files. Generalise the shipped `VocabularyMatchPage` into one
configurable **`WordMatchPage`** (`core_test/presentation/pages/word_match_page.dart`) driven by
constructor data; each question is that page with different `AppStrings` content. This supersedes
the separately-named pages in the spec FRs.

## Reference fidelity (from screenshots)

- Q26/Q30: single word, **right-aligned**, a gap, then the dropdown. **No `=` sign, no
  Example row.** (Both were additions in round 1 — remove them.)
- Q27: definition phrase ("To get better at something is to"), **left-aligned, wraps**, dropdown
  top-aligned to its right.

## Tasks

### 1. `WordMatchingGrid` variant + fidelity
- Add `bool leftAligned = false`. When true: left column uses `TextAlign.left`, a wider width
  (`AppDimensions.matchWordWideWidth`), and rows use `CrossAxisAlignment.start` so long phrases
  wrap and the dropdown top-aligns.
- **Remove the `=` sign** (`AppStrings.matchEqualsSign`) from `_WordMatchingRow`.
- Keep the example row support in code but callers stop passing it (nullable `exampleWord`).
- Existing Q28 is unaffected (does not use this grid).

### 2. Constants
- **`app_dimensions.dart`**: add `matchWordWideWidth` (~360) and `matchRowGapV` if row spacing
  needs a vertical gap for Q27's taller rows.
- **`app_strings.dart`** (grouped, "replace when questions load" TODO):
  - **Q26 fidelity:** change the sample words to the reference set
    `argue / swap / collapse / own / occur` + a synonym option bank per row.
  - **Q27:** `definitionMatchInstruction` = "Complete each definition using a word from the list.
    Use each word once only. You will not need five of the words." + 5 left phrases
    ("To get better at something is to", "To choose something is to", "To get money from work is
    to", "To help someone is to", "To give someone a job is to") + placeholder option banks
    (e.g. improve/select/earn/assist/employ + distractors).
  - **Q30:** `collocationInstruction` = "Select a word from the list that is most often used with
    the word on the left. Use each word once only. You will not need five of the words." +
    `reduced / sentimental / immediate / white-water / semi-precious` + placeholder banks
    (price/value/family/rafting/stone + distractors).

### 3. `WordMatchPage` (generic)
- Rename `vocabulary_match_page.dart` → `word_match_page.dart`; class `VocabularyMatchPage` →
  `WordMatchPage`.
- Constructor: `currentScreen`, `totalScreens`, `timeRemaining`, `required String instruction`,
  `required List<String> words`, `required List<List<String>> optionsList`,
  `bool leftAligned = false`. Drop the example fields/usage.
- State: `Map<int,String?> _answers`; renders `ExamScaffold` + instruction `Text` +
  `WordMatchingGrid(leftAligned: leftAligned, words:…, optionsList:…, answers:…)`.
- Keep the `TODO(sample-data)` / `TODO(exam-flow)` markers.

### 4. Keep the preview compiling
- Update `lib/dev/core_test_preview.dart` to import `word_match_page.dart` and build Q26/Q27/Q30
  as `WordMatchPage(...)` instances (still chip-switched for now; Next/Back nav lands in
  Phase 5). Q1/Q28 unchanged. Q29 is not built.

## Acceptance criteria

- [ ] Q26/Q30 render 5 right-aligned rows, **no `=`, no Example**; counters 26/30 of 30.
- [ ] Q27 renders 5 left-aligned wrapping definition rows; counter 27 of 30.
- [ ] Q26/Q27/Q30 reuse `WordMatchPage` + `WordMatchingGrid` — no duplicated page/grid code.
- [ ] `flutter analyze` clean; each file ≤ 300 lines; `build()` ≤ 50.

## Test (default)

- Update the existing preview import; add `test/widget/word_match_page_test.dart`: pump a
  `WordMatchPage` with sample data, select a dropdown value, assert it persists.
