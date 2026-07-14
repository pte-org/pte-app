# Phase 1 — R1 gap-fill message + R4 heading match (reuse-heavy)

**Covers:** P1 R1, P1 R4, P2 reuse · **Depends on:** none · **Testing:** default

---

## Outcome

The two reuse-heavy Reading screens exist in `lib/features/reading/`: R1 (email with inline
dropdowns) and R4 (scrollable passage + heading dropdowns, split by `ResizableBox`).

## Tasks

### 1. Feature scaffold + constants
- Create `lib/features/reading/presentation/{pages,widgets}/`.
- `app_strings.dart` (grouped, "replace when questions load" TODO):
  - **R1:** `readingGapFillInstruction` ("Choose the word that fits in the gap. the first one is
    done for you."), greeting "Hey Lewis,", signature "Love," / "Helen", 6 line `pre`/`post`
    pairs, per-line option banks, first-gap fixed answer "do".
  - **R4:** `readingHeadingInstruction` ("Read the passage quickly. Choose a heading for each
    numbered paragraph (1-7) from the drop-down box. There is one more heading than you need."),
    the "Mission To Mars" passage paragraphs, and the heading option list (8 headings for 7 gaps).
- Add any new sizes/styles to `AppDimensions`/`AppTextStyles`.

### 2. R1 — `GapFillMessagePage` + inline dropdown
- Reuse the inline-dropdown mechanic from `SentenceCompletionList` (`Text.rich` + `WidgetSpan`).
  If cleanly extractable, lift the styled inline dropdown into a shared widget both features use;
  otherwise mirror it in a reading widget (note the DRY follow-up).
- Page: `ExamScaffold` (currentScreen 1, totalScreens 4), greeting `Text`, the message lines with
  inline dropdowns (first fixed to "do", non-interactive), signature. Local `Map<int,String?>`.

### 3. R4 — `HeadingMatchPage` + `ResizableBox`
- Read `lib/core/widgets/resizable/resizable_box.dart` first to learn its API.
- Layout: split view — left `SingleChildScrollView` with the passage; right a column of 7 boxed
  dropdowns over the heading list. Use `ResizableBox` for the draggable divider if its API fits a
  two-pane split; else a `Row` + fixed divider (Risk #3 fallback) and note it.
- Page: `ExamScaffold` (currentScreen 4, totalScreens 4). Local `Map<int,String?>` for 7 answers.

## Acceptance criteria

- [ ] R1 renders greeting + 6 inline-dropdown lines (first fixed "do") + signature; counter 1/4.
- [ ] R4 renders left passage (scrolls) + 7 heading dropdowns; divider resizes; counter 4/4.
- [ ] R1 reuses the inline-dropdown mechanic; R4 reuses `ResizableBox` (or documented fallback).
- [ ] `flutter analyze` clean; files ≤ 300 lines; `build()` ≤ 50; no inline strings/colors/dims.

## Test (default)

- `test/widget/features/reading/gap_fill_message_page_test.dart`: select a dropdown, assert persists.
- `test/widget/features/reading/heading_match_page_test.dart`: open a heading dropdown, select,
  assert the value shows.
