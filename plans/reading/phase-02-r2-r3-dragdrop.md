# Phase 2 — R2 sentence ordering + R3 word-bank gap-fill (drag & drop)

**Covers:** P1 R2, P1 R3 · **Depends on:** Phase 1 (scaffold) · **Testing:** default

---

## Outcome

The two drag-and-drop Reading screens: R2 (reorder sentences) and R3 (drag word tiles into gaps).

## Tasks

### 1. Constants
- `app_strings.dart` (grouped, TODO):
  - **R2:** `readingOrderingInstruction` ("The sentences below are from a biography. Order the
    sentences to make a story. The first sentence of the story is an example."), the fixed example
    sentence (Audrey Hepburn born…), and the 5 orderable sentences.
  - **R3:** `readingWordBankInstruction` ("Read the text and complete each gap with a word from the
    list at the bottom of the page."), the Galileo passage split into text segments + gap slots,
    the word-tile bank (various/discoveries/taking/lot/around/during/lack/at/serving/experiments),
    and the first-gap fixed answer ("referred").

### 2. R2 — `SentenceOrderingPage`
- `ReorderableListView` (or `.builder`) of tiles. The **first item is the fixed example**:
  render it greyed and non-draggable (exclude from the reorderable range or give it a disabled
  drag handle). The other 5 reorder by drag; keep order in local `List<String>` state.
- Tile style per screenshot: raised, light background, subtle shadow (use `AppColors`/`AppDimensions`).
- Page: `ExamScaffold` (currentScreen 2, totalScreens 4).

### 3. R3 — `WordBankGapFillPage` + drag tiles
- Passage via `Text.rich` with `WidgetSpan` **`DragTarget<String>`** gap slots (same wrap technique
  as Q28's inline dropdown); a `Wrap` of **`Draggable<String>`** word tiles below.
- Dropping a tile onto a gap fills it and removes the tile from the bank; dragging a filled gap out
  (or onto the bank) returns the word. First gap is pre-filled ("referred") and fixed.
- State: `Map<int,String?>` gap→word + the remaining bank list. Page: `ExamScaffold`
  (currentScreen 3, totalScreens 4).
- Keep tiles ≥ comfortable tap size for reliable web dragging (Risk #1).

## Acceptance criteria

- [ ] R2: example row fixed/greyed and non-draggable; the other 5 reorder by drag; order persists.
- [ ] R3: tiles drag from bank into gaps; a placed tile leaves the bank; dragging out returns it;
      first gap fixed; counter 3/4. R2 counter 2/4.
- [ ] `flutter analyze` clean; files ≤ 300 lines; `build()` ≤ 50; no inline strings/colors/dims.

## Test (default)

- `test/widget/features/reading/sentence_ordering_page_test.dart`: drag item, assert order changed.
- `test/widget/features/reading/word_bank_gap_fill_page_test.dart`: drag a tile onto a gap, assert
  the gap shows the word and the tile left the bank.
