# Phase 1 — Q1 Multiple-choice grammar (radio)

**Covers:** [P1] MCQ grammar screen · [P1] reuse `ExamScaffold` + constants
**Testing:** default (1 widget test) · **Depends on:** none

---

## Outcome

A `GrammarMcqPage` (screen 1 of 30) rendering an *Example* group (pre-answered, fixed) and one
real single-select radio question, matching the Q1 screenshot, inside `ExamScaffold`.

## Reference layout (from screenshot)

- No top instruction line. Starts with **"Example"** on its own line.
- Example prompt: `I ______ drunk three cups of coffee this morning`
  - Radio options: **Have** (selected, lime-filled), **Am**, **Are**.
- Real question prompt: `My best friend, ______ is from Australia, is coming to visit me next week.`
  - Radio options: **who**, **which**, **that** (none pre-selected).
- Radio: circle; selected = `AppColors.primaryLime` inner fill inside a light ring; unselected =
  white with a grey ring (`AppColors.dropdownBorder`) + subtle shadow.
- Bottom bar on Q1 shows **Flag + Next only (no Back)**.

## Tasks

### 1. Constants
- **`app_strings.dart`** — add a grammar-MCQ group (grouped, with the same "replace when questions
  load" TODO style as the vocabulary block):
  - `grammarExampleLabel = 'Example'`
  - `grammarExamplePrompt` = the coffee sentence (use a blank token consistent with Q26, e.g. the
    same underscore run used in `vocabulary*`).
  - `grammarExampleOptions = ['Have', 'Am', 'Are']`, `grammarExampleAnswer = 'Have'`
  - `grammarQuestionPrompt` = the Australia sentence.
  - `grammarQuestionOptions = ['who', 'which', 'that']`
- **`app_colors.dart`** — reuse `primaryLime` (selected fill) and `dropdownBorder` (ring). Add
  `radioSelectedRing` / `radioUnselectedShadow` only if the existing tokens don't match visually.
- **`app_dimensions.dart`** — add: `mcqRadioSize`, `mcqRadioInnerSize`, `mcqRadioBorderWidth`,
  `mcqOptionRowGap`, `mcqRadioLabelGap`, `mcqPromptGap`, `mcqGroupGap`.
- **`app_text_styles.dart`** — add: `mcqPrompt`, `mcqOptionLabel`, `mcqExampleLabel`
  (reuse `instruction` sizing where it matches).

### 2. Reusable widget — `widgets/grammar_vocabulary/mcq_question_group.dart`
- `McqQuestionGroup extends StatelessWidget`:
  - fields: `String? exampleLabel`, `required String prompt`, `required List<String> options`,
    `int? selectedIndex`, `ValueChanged<int>? onSelected`, `bool isReadOnly = false`.
  - `build()`: optional example label → prompt `Text` → `Column` of option rows. Keep `build()`
    ≤ 50 lines; extract `_RadioOptionRow` and `_RadioButton` as private classes.
  - `_RadioButton`: circle container; filled inner dot when selected. `const` constructor.
  - Read-only groups (Example) ignore taps (`onSelected == null` or `isReadOnly`).
- Use `const` constructors throughout; no hardcoded strings/colours/dimensions.

### 3. Page — `pages/grammar_vocabulary/grammar_mcq_page.dart`
- `GrammarMcqPage extends StatefulWidget` with defaulted `currentScreen = 1`,
  `totalScreens = 30`, `timeRemaining` (mirror the Q26 page's defaults/const pattern).
- State: `int? _selectedAnswer` for the real question. Example is fixed to its answer index.
- `build()` returns `ExamScaffold(... showBack: false, body: _buildContent())`. `onBack`/`onFlag`/
  `onNext` are TODO stubs mirroring Q26.
- `_buildContent()`: `Column(crossAxisAlignment: start)` with the Example `McqQuestionGroup`
  (read-only), a `SizedBox(mcqGroupGap)`, then the real `McqQuestionGroup` wired to `_selectedAnswer`.
- Add the same `TODO(sample-data)` / `TODO(exam-flow)` markers as Q26.

### 4. Shared frame — optional `showBack` (Risk #1)
- `exam_bottom_bar.dart`: add `bool showBack = true`; when false, render an `Expanded(SizedBox)` in
  place of the Back button + its divider so the Flag/Next block keeps its right-aligned position.
- `exam_scaffold.dart`: add `bool showBack = true`; forward to `ExamBottomBar`.
- Default `true` → Q26/Q28 and any existing caller unchanged.

## Acceptance criteria

- [ ] Q1 renders inside `ExamScaffold`; screen counter shows `1 of 30`.
- [ ] Example group shows "Have" selected and does not respond to taps.
- [ ] Selecting who/which/that updates only the real question; exactly one stays selected.
- [ ] Selected radio uses `AppColors.primaryLime`; bottom bar shows Flag + Next, no Back.
- [ ] `flutter analyze` clean; every new file ≤ 300 lines; every `build()` ≤ 50 lines; no inline
      strings/colours/dimensions.

## Test (default)

- `test/widget/grammar_mcq_page_test.dart`: pump `GrammarMcqPage`, tap "which", assert its radio is
  selected and "who"/"that" are not; tap "that", assert selection moved.
