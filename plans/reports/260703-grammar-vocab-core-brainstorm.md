# Brainstorm: Grammar & Vocabulary — Core screens (rebrand)

**Date:** 2026-07-03

## Ideas Explored

- **Reuse shared exam frame + prior feature convention (chosen).** Wrap all 3 screens
  in the existing `ExamScaffold` and mirror the `VocabularyMatchPage` + `WordMatchingGrid`
  pattern: a `StatefulWidget` holding local answers via `setState`, sample content in
  `AppStrings`, and TODO markers where BLoC/backend wiring lands later. Lowest risk,
  matches the codebase the team already ships.
- **Build a domain `Question` entity + `ExamAttemptBloc` wiring now.** Rejected for this
  pass — the existing screens deliberately defer it (see TODOs in `vocabulary_match_page.dart`
  and `exam_attempt_state.dart`). Introducing it here widens scope beyond "just the 3 screens".
- **Full visual redesign under a new brand.** Rejected — user pointed to the "common" tokens
  in the docs/standards and prior features to reuse, not a new design language. Rebrand is
  treated as a centralized token swap, not a re-layout.
- **Wire the 3 screens into `app.dart` routing.** Deferred — `app.dart` currently pins
  `home: SpeakingPage`. A lightweight preview entry (à la branch `quang/feat/preview-src`)
  is noted as P2, not required for the screens themselves.

## User's Direction

- "chuyển sang brand mới" + "có common trong document và các feature trước hãy tham khảo màn
  hình và tiếp tục làm" → **reuse the shared/common infrastructure and previous-feature
  conventions, follow the screenshots, and proceed.** Action-oriented: do not block on
  brand details.
- Scope fixed to **3 core Grammar & Vocabulary screens** from the screenshots:
  - **Q1 of 30** — multiple-choice grammar with radio options (Example block + 1 real item).
  - **Q26 of 30** — synonym matching with dropdowns → **already built** (`VocabularyMatchPage`).
  - **Q28 of 30** — sentence completion with inline mid-sentence dropdowns.
- Net new build = **Q1 (MCQ radio)** and **Q28 (sentence completion)** only.

## Open Questions

- Literal rebrand contents: is a new product name / logo / palette coming, or keep the
  current British-Council/Aptis lockup + lime/red tokens? (Rebrand is a constants-only swap
  either way.)
- How are these screens reached during dev — point `home:` at each, or add a small preview
  menu? Not required to render the screens, but needed to *see* them.
- Q28: exact word bank (the 10 options — 5 used + 5 distractors) and per-blank correct word.
  Screenshots show blanks but not the dropdown contents.

## Risks

- **Sample-data drift.** Following the existing pattern means more hardcoded content in
  `AppStrings`; when the real `Question` entity arrives, all three screens must be refactored
  together. Keep TODO markers consistent so the migration is one sweep.
- **Layout fidelity.** Q28's inline dropdowns sit *inside* wrapping sentence text (mixed
  `Text` + dropdown on one baseline). Getting wrap + baseline alignment pixel-close to the
  screenshot is the fiddliest part — budget for `Wrap`/`RichText`+`WidgetSpan` iteration.
- **300-line file limit.** Q1 and Q28 each risk exceeding the cap if page + widget live in one
  file. Split into page + a reusable widget under `widgets/grammar_vocabulary/` (same as Q26).
