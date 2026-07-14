# Spec: Reading — core question screens (R1–R4)

**Date:** 2026-07-03
**Status:** Ready
**Code lives in:** `lib/features/reading/` (sibling of `core_test`, `speaking`)

---

## Problem Statement

The Aptis exam needs the **Reading** section's core question screens. Following the same method
as `core_test` (Grammar & Vocabulary): feature-first, reuse `ExamScaffold`, sample data in
`AppStrings`, dev preview walkthrough. Reading has four distinct question types, two of which use
drag-and-drop — more complex than the grammar dropdowns/radios.

## User Stories

- **[P1]** As a test-taker, I want a **gap-fill message screen (R1)** — *"Choose the word that fits
  in the gap…"* — an email with an inline dropdown per line, the first gap pre-filled.
  Accepted when: renders in `ExamScaffold` (counter `1 of 4`), greeting/signature shown, 6 lines
  each with an inline dropdown (first fixed to "do"), selections persist.

- **[P1]** As a test-taker, I want a **sentence-ordering screen (R2)** — *"Order the sentences to
  make a story…"* — 6 sentence tiles, the first a fixed example, the rest **drag-reorderable**.
  Accepted when: counter `2 of 4`; the example row is fixed/greyed and cannot be dragged; the
  other 5 reorder by drag; order persists.

- **[P1]** As a test-taker, I want a **word-bank gap-fill screen (R3)** — *"…complete each gap with
  a word from the list…"* — a passage with gap slots and a word-tile bank; **drag a tile into a
  gap**. The first gap is pre-filled.
  Accepted when: counter `3 of 4`; tiles drag from the bank into gaps and back; a placed tile
  leaves the bank; the pre-filled gap is fixed.

- **[P1]** As a test-taker, I want a **heading-match screen (R4)** — *"Choose a heading for each
  numbered paragraph…"* — a scrollable passage on the left and 7 heading dropdowns on the right,
  split by a **resizable divider**.
  Accepted when: counter `4 of 4`; left passage scrolls; 7 dropdowns each offer the heading list;
  the divider resizes the split via the existing `ResizableBox`.

- **[P1]** As a reviewer, I want **Next/Back to walk R1→R2→R3→R4** in a dev preview on
  `localhost:8080` (replacing the grammar preview), answers persisting across paging.

- **[P2]** As a developer, I want **R1 to reuse the inline-dropdown pattern** from
  `SentenceCompletionList` and **R4 to reuse `ResizableBox`** — no duplicated mechanics.

- **[P3]** _(out of scope) Domain `Question` entity, BLoC/backend, scoring, real part navigation._

## Functional Requirements

1. **FR-01 (feature scaffold):** `lib/features/reading/presentation/{pages,widgets}/`, each screen
   a `StatefulWidget` in `ExamScaffold` with optional `onNext/onBack/onFlag` (mirrors `core_test`).
2. **FR-02 (R1):** `GapFillMessagePage` — greeting + N lines (pre/dropdown/post) + signature, first
   gap fixed. Reuse a shared inline-dropdown row (extract from / mirror `SentenceCompletionList`).
3. **FR-03 (R2):** `SentenceOrderingPage` — `ReorderableListView` with the first item non-draggable
   (fixed example). Tiles styled per screenshot (raised, light).
4. **FR-04 (R3):** `WordBankGapFillPage` — passage `Text.rich` with gap `DragTarget` slots + a
   `Wrap` of `Draggable` word tiles; dropping a tile fills the gap and removes it from the bank;
   dragging out returns it. First gap pre-filled + fixed.
5. **FR-05 (R4):** `HeadingMatchPage` — `ResizableBox`/split layout: left `SingleChildScrollView`
   passage, right column of 7 dropdowns over the shared heading list.
6. **FR-06 (content):** All instructions, message lines, sentences, passages, word banks, heading
   lists as `static const` in `AppStrings` (grouped, "replace when questions load" TODO).
7. **FR-07 (dimensions/styles):** New sizes/styles in `AppDimensions`/`AppTextStyles`; no inline
   magic numbers/strings/colors.
8. **FR-08 (preview):** `lib/dev/reading_preview.dart` — `IndexedStack` of R1–R4 wired to Next/Back;
   runnable via `flutter run -t lib/dev/reading_preview.dart -d chrome --web-port=8080`.

## Non-Functional Requirements

- `flutter analyze` = 0 issues; `flutter test` green.
- Each new `.dart` file ≤ 300 lines; each `build()` ≤ 50 lines; `const` where possible.
- Drag interactions work at the desktop/web viewport shown in the screenshots.

## Success Criteria

- [ ] R1–R4 render matching the screenshots (counters 1–4 of 4).
- [ ] R2 reorders by drag with the example fixed; R3 fills gaps by drag with the bank updating.
- [ ] R4 split resizes via `ResizableBox`; left passage scrolls independently.
- [ ] Preview walks R1→R2→R3→R4 via Next/Back on `localhost:8080`; answers persist.
- [ ] `flutter analyze` = 0; `flutter test` green; files ≤ 300 lines; `build()` ≤ 50.
- [ ] R1 reuses the inline-dropdown mechanic; R4 reuses `ResizableBox` — no duplicated mechanics.

## Out of Scope

- Domain `Question` entity, BLoC/backend, answer scoring, submit, timer, real part navigation.
- Changing production `main.dart`/`app.dart` (preview via `-t`, as with grammar).
- The already-shipped `core_test` grammar screens.

## Assumptions

- Same shared brand tokens as `core_test`; reference is the wide/desktop web layout.
- Screens use `StatefulWidget` + local `setState` + placeholder sample content (approved pattern).
- Reading walkthrough numbers the four types `1..4 of 4` (screenshot counters vary 4/5 across
  Aptis versions; a single consistent total keeps the review clean).

## Resolved Decisions

- **R3 interaction:** drag & drop (`Draggable` + `DragTarget`).
- **Scope:** all four types R1–R4 + preview on `localhost:8080` replacing the grammar preview.
- **Reuse:** R1 mirrors `SentenceCompletionList` inline dropdown; R4 reuses `ResizableBox`.
