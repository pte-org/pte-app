# Phase 2 — Q28 Sentence completion (inline dropdowns)

**Covers:** [P1] sentence-completion screen · [P1] reuse `ExamScaffold` + constants
**Testing:** default (1 widget test) · **Depends on:** none (independent of Phase 1)

---

## Outcome

A `SentenceCompletionPage` (screen 28 of 30) with an instruction line and 5 sentences, each
containing an inline dropdown at the blank, matching the Q28 screenshot, inside `ExamScaffold`.

## Reference layout (from screenshot)

- Instruction (bold, wraps 2 lines): `Finish each sentence using a word from the list. Use each
  word once only. You will not need five of the words.`
- 5 sentences, each = text + an inline dropdown positioned mid-sentence, wrapping across lines:
  1. `After it rained, the path was all [__] and my trainers got dirty.`
  2. `It is important to create an eye-catching [__] when starting a business.`
  3. `My cousin spent a fortune on her wedding. It was incredibly [__]`
  4. `Teachers should always give [__] to their students so they know how to improve.`
  5. `Doing voluntary work is really [__] because it makes you feel like you are making a difference.`
- Dropdown styling = same as Q26: white box, grey border, lime chevron
  (`Icons.arrow_drop_down`, `AppColors.bottomBarBackground`).

## Tasks

### 1. Constants
- **`app_strings.dart`** — add a sentence-completion group (with "replace when questions load" TODO):
  - `sentenceCompletionInstruction` (the 3-sentence instruction above).
  - `sentenceCompletionParts`: a `List` of records/pairs `[pre, post]` for each sentence's text
    around the blank (post may be empty, e.g. sentence 3).
  - `sentenceCompletionWordBank`: **placeholder** 10-word sample (5 plausible answers + 5
    distractors), e.g. `['muddy','brand','lavish','feedback','rewarding','slippery','expense',
    'comment','generous','dusty']`. Placeholder is approved (see spec Resolved Decisions).
- **`app_dimensions.dart`** — add: `sentenceLineHeight`, `sentenceRowGap`,
  `sentenceInlineDropdownWidth` (reuse `matchDropdownWidth`/`matchDropdownHeight` where they fit),
  plus a `sentenceInlineDropdownWidthWide` variant for the longer blank (sentence 3).
- **`app_text_styles.dart`** — add `sentenceText` (matches instruction body sizing).

### 2. Reusable widget — `widgets/grammar_vocabulary/sentence_completion_list.dart`
- `SentenceCompletionList extends StatelessWidget`:
  - fields: `required List<(String pre, String post)> sentences`,
    `required List<String> wordBank`, `required Map<int, String?> answers`,
    `required void Function(int index, String? value) onAnswerChanged`.
  - `build()`: `Column` of `_SentenceRow`s separated by `sentenceRowGap`. ≤ 50 lines.
  - `_SentenceRow`: render with `Text.rich` containing
    `TextSpan(pre)` + `WidgetSpan(alignment: PlaceholderAlignment.middle, child: _InlineDropdown)`
    + `TextSpan(post)` so text and dropdown flow and **wrap together**.
  - `_InlineDropdown`: mirror `WordMatchingGrid._Dropdown` visuals (border, lime chevron,
    `DropdownButtonHideUnderline`). Do **not** refactor Q26's copy now (out of scope; see plan Risk #4).
- All `const` where possible; no hardcoded strings/colours/dimensions.

### 3. Page — `pages/grammar_vocabulary/sentence_completion_page.dart`
- `SentenceCompletionPage extends StatefulWidget` with defaulted `currentScreen = 28`,
  `totalScreens = 30`, `timeRemaining` — mirror the Q26 page structure exactly.
- State: `Map<int, String?> _answers` (one per sentence), initialised to `null`.
- `build()` → `ExamScaffold(... body: _buildContent())`; `onBack`/`onFlag`/`onNext` TODO stubs.
  Bottom bar keeps Back (default `showBack: true`) — Q28 shows Back in the reference.
- `_buildContent()`: instruction `Text` (`AppTextStyles.instructionBold`) → gap →
  `SentenceCompletionList` wired to `_answers` + `setState` on change (mirror Q26's `onAnswerChanged`).
- Same `TODO(sample-data)` / `TODO(exam-flow)` markers as Q26.

## Acceptance criteria

- [ ] Q28 renders inside `ExamScaffold`; screen counter shows `28 of 30`.
- [ ] Instruction text matches the screenshot; 5 sentences render with an inline dropdown each.
- [ ] Sentence text + dropdown wrap together on narrow width (no overflow).
- [ ] Each dropdown lists the shared word bank; a selection persists across rebuild.
- [ ] `flutter analyze` clean; every new file ≤ 300 lines; every `build()` ≤ 50 lines; no inline
      strings/colours/dimensions.

## Test (default)

- `test/widget/sentence_completion_page_test.dart`: pump `SentenceCompletionPage`, open the first
  sentence's dropdown, select a word, assert it shows as the dropdown value.
