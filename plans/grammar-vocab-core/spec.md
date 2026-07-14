# Spec: Grammar & Vocabulary — Core screens (Q1 MCQ + Q28 sentence completion)

**Date:** 2026-07-03
**Status:** Ready

---

## Problem Statement

The Aptis exam-delivery flow needs the core **Grammar & Vocabulary** question screens that a
test-taker sees. The synonym-matching screen (Q26) already exists; the multiple-choice grammar
screen (Q1) and the sentence-completion screen (Q28) do not. This spec covers building those two
to match the reference screenshots, reusing the shared exam frame and the conventions already set
by `VocabularyMatchPage`.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As a test-taker, I want a **multiple-choice grammar screen (Q1)** with a worked
  *Example* block and radio options per question, so I can answer single-select grammar items.
  Accepted when: the screen renders inside `ExamScaffold`, shows the pre-answered Example
  (radio "Have" filled), lets me select exactly one option per real question, and the selected
  radio shows the lime fill from the reference.

- **[P1]** As a test-taker, I want a **sentence-completion screen (Q28)** where each sentence has
  an inline dropdown, so I can pick one word per blank from a shared word bank.
  Accepted when: the instruction line matches the screenshot, 5 sentences each render an inline
  dropdown at the correct mid-sentence position, text wraps cleanly, and each dropdown offers the
  shared word list.

- **[P1]** As a developer, I want both screens to **reuse `ExamScaffold` + centralized constants**
  and mirror the `VocabularyMatchPage`/`WordMatchingGrid` structure, so the codebase stays uniform.
  Accepted when: no new architecture is introduced; strings/colors/dimensions/text-styles all come
  from `AppStrings`/`AppColors`/`AppDimensions`/`AppTextStyles`; each new file ≤ 300 lines and each
  `build()` ≤ 50 lines.

- **[P2]** As a developer, I want a **lightweight way to preview the 3 core screens** during dev
  (e.g. a temporary route/menu or swappable `home:`), so the screens can be visually verified.
  Accepted when: each of Q1, Q26, Q28 can be opened without editing multiple files.

- **[P2]** As the product owner, I want the **rebrand to be a single centralized swap** (name,
  logo text, palette), so switching brand does not touch screen code.
  Accepted when: brand name/logo/colors live only in `AppStrings`/`AppColors`; changing them
  restyles all three screens with no widget edits.

- **[P3]** _(out of scope) Wiring screens to real `Question` data via `ExamAttemptBloc`/backend._
- **[P3]** _(out of scope) Answer validation, scoring, timer countdown behavior, submit flow._

---

## Functional Requirements

1. **FR-01 (Q1 page):** New `GrammarMcqPage` (StatefulWidget) wrapped in `ExamScaffold` with
   `currentScreen: 1, totalScreens: 30`. Holds selected-option state locally via `setState`.
2. **FR-02 (Q1 example):** Render an "Example" label + prompt (`I ______ drunk three cups of
   coffee this morning`) with options `Have / Am / Are`, `Have` pre-selected and non-interactive.
3. **FR-03 (Q1 question):** Render the real item (`My best friend, ______ is from Australia, is
   coming to visit me next week.`) with options `who / which / that`, single-select radio.
4. **FR-04 (radio widget):** A reusable `McqOptionList` (or similar) under
   `widgets/grammar_vocabulary/` rendering one radio row per option; selected state shows the lime
   fill (`AppColors.primaryLime`) and unselected shows the `AppColors.dropdownBorder` ring.
5. **FR-05 (Q28 page):** New `SentenceCompletionPage` (StatefulWidget) wrapped in `ExamScaffold`
   with `currentScreen: 28, totalScreens: 30`. Holds one selected word per sentence locally.
6. **FR-06 (Q28 instruction):** Show `Finish each sentence using a word from the list. Use each
   word once only. You will not need five of the words.`
7. **FR-07 (Q28 sentences):** Render 5 sentences, each with an inline dropdown positioned at the
   blank (mid-sentence), text wrapping across lines as in the screenshot.
8. **FR-08 (Q28 dropdown widget):** A reusable `SentenceCompletionList` under
   `widgets/grammar_vocabulary/` reusing the existing dropdown styling (border, lime chevron)
   from `WordMatchingGrid`'s `_Dropdown`.
9. **FR-09 (content constants):** All instructions, example/question text, options, and the Q28
   word bank live as `static const` in `AppStrings`, grouped with a "replace when questions load"
   TODO — matching the existing vocabulary sample block.
10. **FR-10 (new dimensions/styles):** Any new sizes (radio size, option row gap, sentence line
    height, inline dropdown width) added to `AppDimensions`; any new text styles to
    `AppTextStyles`. No inline magic numbers/colors/strings.

---

## Non-Functional Requirements

- **Performance:** Static screens; no async in `build()`, no repository calls. Const constructors
  on all leaf widgets.
- **Code standard:** Passes `flutter analyze` with zero warnings. Every new `StatefulWidget`
  with controllers/subscriptions overrides `dispose()` (none expected here, but enforced if added).
- **Structure:** Each new `.dart` file ≤ 300 lines; each `build()` ≤ 50 lines; sub-widgets are
  private `_Name` classes or separate files under `widgets/grammar_vocabulary/`.

---

## Success Criteria

- [ ] **Visual parity:** Q1 and Q28 rendered on desktop web/large viewport visually match the
      reference screenshots (layout, radio/dropdown styling, spacing) on side-by-side review.
- [ ] **Q1 interaction:** Selecting an option updates only that question's selection; Example row
      stays fixed on "Have".
- [ ] **Q28 interaction:** Each sentence's dropdown independently opens and shows the shared word
      bank; selection persists on rebuild.
- [ ] **Standards:** `flutter analyze` = 0 issues; every new file ≤ 300 lines; every `build()`
      ≤ 50 lines; zero hardcoded strings/colors/dimensions in the new widgets.
- [ ] **Reuse:** New screens import and render `ExamScaffold`; Q28 dropdown reuses the same visual
      treatment as the existing `WordMatchingGrid` dropdown.

---

## Out of Scope

- Domain `Question` entity, `ExamAttemptBloc` wiring, and backend/API submission.
- Answer correctness, scoring, and results.
- Timer countdown logic, flag persistence, and real Next/Back navigation between parts.
- Any literal new brand asset creation (logo art, new palette values) — only the centralized
  swap mechanism is in scope.
- Rebuilding or restyling the already-shipped Q26 (`VocabularyMatchPage`).

---

## Assumptions

- The two new screens follow the exact pattern of `VocabularyMatchPage`: `StatefulWidget` +
  local `setState`, sample data in `AppStrings`, TODO markers for future BLoC wiring.
- The current shared brand tokens (`AppColors` lime `#D5E33A` / red `#CC0000`, British-Council/
  Aptis lockup) are the intended brand unless clarified otherwise.
- Reference viewport is the desktop/web layout shown in the screenshots (wide, single column).
- Q1 has exactly one Example + one real question (as shown); Q28 has exactly 5 sentences with a
  10-word bank (5 used + 5 distractors) per the instruction text.

---

## Resolved Decisions

<!-- Confirmed 2026-07-03 — user approved proceeding to /ck:plan with these choices. -->

- **Rebrand contents:** Keep the current shared brand tokens (`AppColors` lime `#D5E33A` /
  red `#CC0000`, British-Council/Aptis lockup). A literal rebrand remains a future centralized
  swap in `AppStrings`/`AppColors` (P2), not part of this build.
- **Q28 word bank + answers:** Use **placeholder sample content** in `AppStrings` (same approach
  as the existing vocabulary sample), with a TODO to replace when real questions load. Exact
  10-word bank and per-blank answers not required for this UI pass.
- **Preview mechanism (P2):** Temporarily repoint `home:` per screen for visual verification;
  a dedicated dev preview menu is optional/not required.

---
---

# Round 2 — Full question set + review navigation

**Date:** 2026-07-03 · **Status:** Ready · **Code lives in:** `lib/features/core_test/`

## Problem Statement

The Grammar & Vocabulary section has **five question types** across Q26–Q30, plus the Q1
multiple-choice. Round 1 shipped Q1, Q26, Q28. Three screens are still missing (Q27, Q29, Q30),
and the Next/Back buttons are no-op stubs, so the built screens can't be reviewed as a sequence.

## User Stories

- **[P1]** As a test-taker, I want a **definition-match screen (Q27)** — *"Complete each definition
  using a word from the list…"* — with a left-aligned wrapping phrase and a dropdown per row.
  Accepted when: 5 definition rows render inside `ExamScaffold` (counter `27 of 30`), left phrases
  left-aligned and wrapping, each with its own dropdown over the shared word bank.

- **[P1]** As a test-taker, I want a **collocation-match screen (Q30)** — *"…most often used with
  the word on the left…"* (reduced/sentimental/immediate/white-water/semi-precious). Accepted
  when: it renders via the reused `WordMatchingGrid` (counter `30 of 30`), 5 rows, no example row.

- **[P1]** As a reviewer, I want **Next/Back to move between the built screens** so I can walk the
  set. Accepted when: in the dev preview, Next advances Q1 → Q26 → Q27 → Q28 → Q30 and Back
  reverses; each screen shows its real number; answers persist when paging back and forth.

- **[P2]** As a stakeholder, I want the **match screens to match the reference exactly** — no
  "Example" row on Q26/Q29/Q30. Accepted when: `VocabularyMatchPage` (Q26) and the new Q29/Q30
  render 5 plain rows with no example.

- **[P3]** _(out of scope) Production part-navigator + `Question` model + BLoC-driven flow._

## Functional Requirements

1. **FR-R2-01 (Q27 page):** `DefinitionMatchPage` in `core_test/presentation/pages/`, default
   `currentScreen: 27`, reusing `WordMatchingGrid` in a **left-aligned / wider-column** mode.
2. **FR-R2-02 (grid variant):** Add `leftAligned` (bool) + a wider left-column width to
   `WordMatchingGrid` so definition phrases left-align, wrap, and top-align with the dropdown.
   Existing Q26/Q28 callers unaffected (defaults preserve current behaviour).
3. **FR-R2-04 (Q30 page):** `CollocationMatchPage`, default `currentScreen: 30`, reused grid,
   no example row. _(Q29 dropped — see Resolved Decisions.)_
5. **FR-R2-05 (content):** Instructions + left labels + placeholder word banks for Q27/Q29/Q30 as
   `static const` in `AppStrings`, grouped, with the "replace when questions load" TODO.
6. **FR-R2-06 (example row removed):** `VocabularyMatchPage` (Q26) and Q29/Q30 render with no
   example row, matching the reference.
7. **FR-R2-07 (optional nav callbacks):** Each `core_test` page accepts optional
   `onNext`/`onBack`/`onFlag`; when null it keeps standalone behaviour (Q1 keeps `showBack:false`).
8. **FR-R2-08 (preview walkthrough):** `lib/dev/core_test_preview.dart` holds the ordered 6 screens
   in an `IndexedStack`, injects `onNext`/`onBack` that change the index, and drops the top chips.
   Next past Q30 and Back before Q1 are no-ops.

## Success Criteria

- [ ] Q27, Q30 render matching their screenshots (counters 27/30 of 30); Q26/Q30 have no
      example row and no `=`.
- [ ] In the preview, Next/Back walk Q1→Q26→Q27→Q28→Q30 and answers persist across paging.
- [ ] `flutter analyze` = 0 issues; `flutter test` green; every new file ≤ 300 lines, `build()` ≤ 50.
- [ ] Q30 adds **no** new dropdown/grid code — it reuses `WordMatchingGrid`/`WordMatchPage`.

## Resolved Decisions (Round 2)

- **Q29 dropped:** it is the same synonym-match layout as Q26, so it adds nothing to the review.
  Build set is **Q1, Q26, Q27, Q28, Q30**; new screens to build are **Q27 + Q30**.
- **DRY:** one generic `WordMatchPage` (data via constructor) serves Q26/Q27/Q30; not separate
  page files.
- **Fidelity:** remove the `=` sign and the Example row from the match screens; keep the existing
  sample words for Q26 (placeholder — layout matters more than exact words).
- **Next flow:** chains the 5 built screens with real question numbers (1, 26, 27, 28, 30);
  Q30 Next = end.
- **Navigator location:** dev preview only (`lib/dev/core_test_preview.dart`); `core_test` pages
  stay standalone via optional callbacks.
- **Word banks (Q27/Q30):** placeholder sample content, TODO-marked.
