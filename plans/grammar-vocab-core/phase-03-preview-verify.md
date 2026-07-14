# Phase 3 — Preview + verify

**Covers:** [P2] preview mechanism · all success criteria
**Testing:** gate · **Depends on:** Phase 1 + Phase 2

---

## Outcome

The three core screens (Q1, Q26, Q28) can be opened for visual verification, and the whole change
passes the standards gate.

## Tasks

### 1. Preview (P2 — lightweight)
- Verify each screen by temporarily pointing `app.dart` `home:` at `GrammarMcqPage`,
  `VocabularyMatchPage`, then `SentenceCompletionPage` in turn (revert `home:` to its original
  `SpeakingPage` before finishing — do not commit a changed entrypoint).
- Do **not** build routing/navigation between parts (out of scope, P3).

### 2. Standards gate
- `flutter analyze` → **0 issues**.
- Confirm every new/edited file ≤ 300 lines (`wc -l`), every `build()` ≤ 50 lines.
- Grep the new widgets for violations: no bare `Color(0x`, no inline string literals in `Text(...)`,
  no magic numbers — all via `AppColors` / `AppStrings` / `AppDimensions`.
- Run the two new widget tests + existing suite: `flutter test`.

### 3. Visual parity review
- Side-by-side Q1 and Q28 against the reference screenshots at the wide/desktop viewport:
  layout, radio/dropdown styling, spacing, wrap behaviour.

## Acceptance criteria (whole feature)

- [ ] Q1, Q26, Q28 each render correctly via the temporary preview.
- [ ] `flutter analyze` = 0 issues; `flutter test` green.
- [ ] Visual parity confirmed for Q1 and Q28.
- [ ] `app.dart` entrypoint reverted to `SpeakingPage` (no stray preview change committed).
- [ ] No changes to the shipped Q26 behaviour/appearance.
