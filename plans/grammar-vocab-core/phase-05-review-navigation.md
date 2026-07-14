# Phase 5 — Review navigation (Next/Back through the 5 screens)

**Covers:** R2 P1 (Next/Back review walkthrough) · **Depends on:** Phase 4
**Testing:** default

---

## Outcome

In the dev preview, **Next/Back walk the 5 built screens** in order
(Q1 → Q26 → Q27 → Q28 → Q30) with real question numbers; answers persist across paging.
The `core_test` pages stay standalone (navigation lives only in the preview). Q29 is not part
of the set.

## Tasks

### 1. Optional nav callbacks on every page
- Add optional `VoidCallback? onNext`, `onBack`, `onFlag` to `GrammarMcqPage`, `WordMatchPage`,
  `SentenceCompletionPage`.
- In each `build()`: pass `onNext: widget.onNext ?? () {}` (same for back/flag) to `ExamScaffold`.
  Standalone behaviour unchanged when the callbacks are null.
- Leave `GrammarMcqPage` `showBack: false` (it is first in the chain, so Back stays hidden there).

### 2. Preview walkthrough (`lib/dev/core_test_preview.dart`)
- Replace the top `ChoiceChip` switcher with an ordered list of the 5 configured screens in an
  `IndexedStack` (so each keeps its answer state when paging back and forth).
- Hold `int _index`; build each screen with:
  - `onNext: _index < last ? () => setState(() => _index++) : null-equivalent no-op`
  - `onBack: _index > 0 ? () => setState(() => _index--) : no-op`
- Order + real screen numbers: Q1 (1) → Q26 (26) → Q27 (27) → Q28 (28) → Q30 (30).
  Each screen already defaults/receives its real `currentScreen`; `totalScreens: 30`.
- Next past Q30 and Back before Q1 are no-ops (first screen also hides Back via `showBack:false`).

## Acceptance criteria

- [ ] Pressing **Next** advances Q1→Q26→Q27→Q28→Q30; **Back** reverses (from Q26 onward).
- [ ] Each screen shows its real number (1, 26, 27, 28, 30) in the counter.
- [ ] Answers entered on a screen are still there after paging away and back (IndexedStack).
- [ ] `core_test` pages compile and run standalone (callbacks optional); `flutter analyze` clean.

## Test (default)

- `test/widget/core_test_preview_nav_test.dart`: pump the preview root, assert Q1 visible
  (`Screen … 1 … 30` / "Example"), tap Next, assert Q26 content visible; tap Back, assert Q1 again.
