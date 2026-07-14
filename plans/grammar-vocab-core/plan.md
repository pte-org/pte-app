# Plan: Grammar & Vocabulary — Core screens (Q1 MCQ + Q28 sentence completion)

**Spec:** [spec.md](./spec.md)
**Date:** 2026-07-03
**Mode:** Fast · **Testing:** default (light widget tests) · **Status:** Ready to cook

---

## Goal

Build the two missing core Grammar & Vocabulary screens to match the reference screenshots,
reusing the shared `ExamScaffold` frame and mirroring the shipped `VocabularyMatchPage` +
`WordMatchingGrid` conventions. Q26 (synonym match) already exists and is untouched.

## Approach

Both screens are `StatefulWidget`s that keep answer state locally (`setState`) and read sample
content from `AppStrings` — identical to the existing Q26 page. No domain `Question` entity, no
BLoC/backend wiring (deferred, TODO-marked). Every string / colour / dimension / text-style comes
from the central constant files.

## Reference files (read before editing)

- Frame: [exam_scaffold.dart](../../lib/core/widgets/exam/exam_scaffold.dart),
  [exam_bottom_bar.dart](../../lib/core/widgets/exam/exam_bottom_bar.dart)
- Pattern to mirror: [vocabulary_match_page.dart](../../lib/features/exam_delivery/presentation/pages/grammar_vocabulary/vocabulary_match_page.dart),
  [word_matching_grid.dart](../../lib/features/exam_delivery/presentation/widgets/grammar_vocabulary/word_matching_grid.dart)
- Constants: [app_colors.dart](../../lib/core/constants/app_colors.dart),
  [app_strings.dart](../../lib/core/constants/app_strings.dart),
  [app_dimensions.dart](../../lib/core/constants/app_dimensions.dart),
  [app_text_styles.dart](../../lib/core/constants/app_text_styles.dart)

## Phases

| # | Phase | Covers stories | File | Done |
|---|-------|----------------|------|------|
| 1 | Q1 — Multiple-choice grammar (radio) | P1 (MCQ), P1 (reuse) | [phase-01-grammar-mcq.md](./phase-01-grammar-mcq.md) | [x] |
| 2 | Q28 — Sentence completion (inline dropdowns) | P1 (sentence), P1 (reuse) | [phase-02-sentence-completion.md](./phase-02-sentence-completion.md) | [x] |
| 3 | Preview + verify | P2 (preview), all success criteria | [phase-03-preview-verify.md](./phase-03-preview-verify.md) | [x] |

Phases 1 and 2 are independent (touch different files); phase 3 depends on both.

### Round 2 phases (2026-07-03) — full set + review navigation

| # | Phase | Covers stories | File | Done |
|---|-------|----------------|------|------|
| 4 | Q27/Q30 screens + grid variant + drop example row (Q29 dropped) | R2 P1 (Q27/Q30), R2 P2 (no example) | [phase-04-fullset-screens.md](./phase-04-fullset-screens.md) | [x] |
| 5 | Review navigation — optional page callbacks + preview walkthrough | R2 P1 (Next/Back review) | [phase-05-review-navigation.md](./phase-05-review-navigation.md) | [x] |
| 6 | Verify full set + Next/Back walkthrough | all R2 success criteria | [phase-06-fullset-verify.md](./phase-06-fullset-verify.md) | [x] |

Phase 4 → 5 → 6 run in order (5 wires the screens 4 produces; 6 verifies both).
Code lives in `lib/features/core_test/`; navigation lives only in `lib/dev/core_test_preview.dart`.

## Story → phase mapping

- **[P1] MCQ grammar screen** → Phase 1
- **[P1] Sentence-completion screen** → Phase 2
- **[P1] Reuse `ExamScaffold` + constants** → Phases 1 & 2 (enforced in each phase checklist)
- **[P2] Preview mechanism** → Phase 3
- **[P2] Rebrand = centralized swap** → already satisfied (screens read only from constants); no work
- **[P3] BLoC/backend, scoring, timer** → out of scope, TODO markers only

## Testing strategy

`test/` currently holds unit tests only (bloc/network/storage/sync); no page widget tests exist.
Default approach:
- **Automated:** `flutter analyze` = 0 issues (gate). Add 2 light widget tests under `test/widget/`
  — one asserting Q1 radio single-select updates selection, one asserting Q28 dropdown selection
  persists. Keep minimal; they are the first page widget tests, so establish a simple pattern.
- **Manual:** visual parity review of Q1 and Q28 against the screenshots at the wide/desktop
  viewport (temporarily repoint `home:` — see Phase 3).

## Risks (self-reviewed — Fast mode, no red-team agent)

1. **Q1 has no Back button in the reference**, but shared `ExamBottomBar` always renders Back.
   → Decision: add an optional `showBack` (default `true`) param to `ExamScaffold` + `ExamBottomBar`
   (backward-compatible; Q26/Q28 unaffected). Handled in Phase 1. If rejected, accept the deviation.
2. **Q28 inline dropdown inside wrapping text** is the fiddliest layout. → Use `Text.rich` +
   `WidgetSpan(alignment: PlaceholderAlignment.middle)` so the dropdown flows and wraps with the
   sentence. Budget iteration on baseline alignment.
3. **300-line file limit.** → Split each screen into page + a widget file under
   `widgets/grammar_vocabulary/` (mirrors Q26). Sub-widgets are private `_Name` classes.
4. **Dropdown duplication (DRY).** Q28's styled dropdown duplicates `WordMatchingGrid._Dropdown`.
   That's the 2nd occurrence (rule mandates extraction at the 3rd). → Do NOT refactor Q26 now
   (out of scope). Note a follow-up to extract a shared `ExamDropdown` when a 3rd use appears.
5. **Sample content is placeholder.** → Group all new sample data in `AppStrings` with the same
   "replace when questions load" TODO as the existing vocabulary block, so the future migration is
   one sweep.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-07-03
**Phase in progress:** (all complete — Rounds 1 & 2)
**Status:** Round 2 done. Built Q27 + Q30, generalized `VocabularyMatchPage` → `WordMatchPage`, `WordMatchingGrid` gained `leftAligned`, dropped `=`/Example, wired Next/Back walkthrough (Q1→Q26→Q27→Q28→Q30) in the dev preview. `flutter analyze lib test` = 0; `flutter test` = 34/34. Visually walked all 5 screens — match references. **Q29 dropped.** Not committed (awaiting user).

### Deviations (transparent)
- No automated widget test for the preview walkthrough nav: `IndexedStack` keeps all screens in the tree (offstage), so `find.text` can't disambiguate the visible screen. Nav verified visually instead. The 3 page-level widget tests (mcq, sentence, word-match) cover per-screen interaction.

> **Relocation (2026-07-03):** Per team lead, grammar/vocab is its own top-level feature
> `lib/features/core_test/` (sibling of `speaking`), NOT under `exam_delivery`. All grammar/vocab
> pages/widgets (Q1, Q26, Q28) moved to `core_test/presentation/{pages,widgets}/`. Shared exam
> frame stays in `lib/core/widgets/exam/`. Any `exam_delivery/.../grammar_vocabulary/` path in the
> phase docs below now reads as `core_test/presentation/`.

### Decisions made this session
- Added optional `showBack` (default true) to ExamScaffold + ExamBottomBar; Q1 sets it false.
- Grammar prompts store the blank inline as one string (no pre/post split) — simpler than Q28.
- Radio visuals: selected = pale-lime bg + lime border + lime inner dot; unselected = white + grey border + subtle shadow. New tokens in AppColors (radioBorder, radioSelectedBackground, radioShadow).
- Q28 inline dropdown = `Text.rich` + `WidgetSpan(alignment: middle)`; parallel `pre`/`post` string lists (mirrors Q26's parallel-list sample pattern). Uniform dropdown width (KISS; word-bank words are short) instead of a per-sentence wide variant.
- Q28 dropdown visuals duplicate WordMatchingGrid._Dropdown (2nd use). Not extracted (Q26 out of scope) — extract shared ExamDropdown at 3rd use.

### Next immediate action
Visual parity is the one remaining manual step (functional render verified by widget tests). Optionally `flutter run` with `home:` repointed per page. Then commit.
