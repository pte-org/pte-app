# Plan: Reading — core question screens (R1–R4)

**Spec:** [spec.md](./spec.md)
**Date:** 2026-07-03 · **Mode:** Fast · **Testing:** default (light widget tests) · **Status:** Ready to cook

---

## Goal

Build the four Reading question-type screens (R1 gap-fill message, R2 sentence ordering,
R3 word-bank gap-fill, R4 heading match) in a new `lib/features/reading/` feature, mirroring the
`core_test` method, plus a dev preview walkthrough on `localhost:8080`.

## Approach

Same as `core_test`: `StatefulWidget` + local `setState`, sample data in `AppStrings`, optional
`onNext/onBack/onFlag`, `ExamScaffold` frame, `-t` dev preview (no `main.dart`/`app.dart` change).
Reuse: R1 ← inline-dropdown mechanic (`SentenceCompletionList`); R4 ← `ResizableBox`.

## Reference files

- Method to mirror: `lib/features/core_test/presentation/pages/*`,
  `lib/features/core_test/presentation/widgets/sentence_completion_list.dart`
- Frame: `lib/core/widgets/exam/exam_scaffold.dart`
- Split-pane: `lib/core/widgets/resizable/resizable_box.dart`
- Dev preview to mirror: `lib/dev/core_test_preview.dart`

## Phases

| # | Phase | Covers | File | Done |
|---|-------|--------|------|------|
| 1 | Scaffold + R1 (gap-fill message) + R4 (heading match, ResizableBox) | P1 R1, P1 R4, P2 reuse | [phase-01-r1-r4-reuse.md](./phase-01-r1-r4-reuse.md) | [x] |
| 2 | R2 (sentence ordering, drag) + R3 (word-bank gap-fill, drag) | P1 R2, P1 R3 | [phase-02-r2-r3-dragdrop.md](./phase-02-r2-r3-dragdrop.md) | [x] |
| 3 | Preview walkthrough on localhost:8080 + verify | P1 review nav, all criteria | [phase-03-preview-verify.md](./phase-03-preview-verify.md) | [x] |

## Session Notes
<!-- Updated by cook automatically -->

**Last active:** 2026-07-04
**Status:** All 3 phases done. `flutter analyze` = 0 reading issues (7 pre-existing dev warnings only); `flutter test` = 40/40. Visually walked R1→R2→R3→R4 on localhost:8080 — all match references; R3 drag-to-fill confirmed (tile leaves bank), R4 split-pane + divider work. Not committed.

### Decisions
- Extracted shared `core/widgets/exam/inline_dropdown.dart` (`InlineDropdown`, nullable onChanged for locked gaps); refactored Q28's `SentenceCompletionList` to use it (DRY, no behaviour change).
- R4 split-pane built as a custom draggable two-pane split (ResizableBox is a corner-resize of one box, not a horizontal splitter — Risk #3 fallback).
- R2 uses `ReorderableListView(header:)` for the fixed example + `onReorderItem` (onReorder deprecated in Flutter 3.44.4).
- `_GapBox` uses a fixed width (a childless Container with only minWidth expanded to full width).

### Deviations (transparent)
- R2/R3 have render smoke tests only (drag & ReorderableListView drags are unreliable in widget tests); drag behaviour verified visually instead.
- Preview nav has no widget test (IndexedStack offstage — same caveat as core_test).

Phase 1 → 2 build screens (independent widgets); Phase 3 wires the preview + verifies.

## Risks (self-reviewed — Fast mode)

1. **Drag-and-drop on web (R2/R3).** `ReorderableListView` (R2) and `Draggable`/`DragTarget` (R3)
   behave on Flutter web but need testing at the target viewport. Keep tiles large enough to grab.
2. **R3 gap slots inside wrapping text.** Use `Text.rich` + `WidgetSpan` DragTargets (same wrap
   technique as Q28's inline dropdown). Budget iteration on baseline/wrap.
3. **R4 split-pane sizing.** Reuse `ResizableBox` as-is; if its API doesn't fit a two-pane split,
   fall back to a simple `Row` with a fixed divider and note it (don't rebuild ResizableBox).
4. **300-line limit.** R3/R4 are the biggest — split each into page + widget file(s).
5. **DRY dropdown (3rd+ use).** R1 and R4 both need a styled dropdown; R1 reuses the inline one and
   R4 the boxed one. If a 3rd distinct copy appears, extract a shared `ExamDropdown` then.

## Testing strategy

`flutter analyze` = 0 (gate) + light widget tests per screen under
`test/widget/features/reading/`: R1 dropdown persists, R2 reorder changes order, R3 drop fills a
gap, R4 dropdown persists. Preview nav verified visually (IndexedStack offstage — same caveat as
core_test). Visual walkthrough screenshots in Phase 3.
