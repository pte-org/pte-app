# Brainstorm: Core Test — full Grammar & Vocabulary set + review navigation

**Date:** 2026-07-03
**Continuation of:** [260703-grammar-vocab-core-brainstorm.md](./260703-grammar-vocab-core-brainstorm.md)

## Ideas Explored

- **Reuse `WordMatchingGrid` for Q29 + Q30 (chosen).** Both are the identical
  "word-left → dropdown-right" layout as the shipped Q26; only the instruction text and
  word bank differ. Near-free to add — a page each + sample data.
- **Q27 as a `WordMatchingGrid` variant (chosen).** The definition items ("To get better at
  something is to ___") are long, **left-aligned, wrapping** phrases, unlike the short
  right-aligned single words of Q26/29/30. Add `leftAligned` + wider-column params to the grid
  rather than a whole new widget (DRY — same dropdown, same row structure).
- **Remove the "Example" row from the match screens (chosen).** The real Q26/29/30 show 5 plain
  word→dropdown rows with **no** example. The shipped `VocabularyMatchPage` renders an example
  ("big = large") — drop it to match the reference.
- **Review navigation via Next/Back (chosen, preview-only).** `onNext`/`onBack` are currently
  no-op stubs, so Next does nothing. Wire a small ordered walkthrough so pressing Next moves to
  the next screen. Per user: this lives **only in the dev preview** (`lib/dev/core_test_preview.dart`);
  the `core_test` pages stay standalone.
- **Production part-navigator + BLoC (rejected for now).** A real question-flow container driven
  by a `Question` model / BLoC is the eventual design, but out of scope — deferred with the rest
  of the backend wiring.

## User's Direction

- Complete the **3 missing Grammar & Vocab screens**: Q27 (definition match), Q29 (synonym match
  #2), Q30 (collocation match). Q1/Q26/Q28 already done.
- **Next/Back chains all 6 built screens** in order (Q1 → Q26 → Q27 → Q28 → Q29 → Q30) with the
  **real question numbers** in the counter (1, 26, 27, 28, 29, 30). Next on Q30 = end.
- The navigator lives **only in the dev preview** — pages remain standalone; the review is driven
  by the in-app Next/Back buttons, replacing the preview's top chips.

## Open Questions

- Word banks + correct answers for Q27/Q29/Q30 are not in the screenshots → use **placeholder
  sample** content (approved pattern), TODO-marked for the real data.
- Should `onNext` on the last screen (Q30) be disabled/greyed, or just do nothing? (Assume: no-op.)

## Risks

- **Q27 alignment fidelity.** Left-aligned, wrapping, top-aligned dropdown row differs from the
  right-aligned grid — budget a little iteration on the variant.
- **State persistence across nav.** Use an `IndexedStack` in the preview so each page keeps its
  selected answers when the user pages back and forth.
- **Screens carry standalone defaults.** Pages must accept optional `onNext`/`onBack` without
  losing their standalone behaviour (default to the current pop/no-op).
