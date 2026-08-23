# Spec: Writing Tasks (Summarize Written Text + Write Essay)

**Date:** 2026-08-23
**Status:** Ready
**Code lives in:** `lib/features/exam_attempt/` (existing screen folder)

---

## Problem Statement

The Aptis Writing section needs the **Summarize Written Text** and **Write Essay** screens rendered with a shared header + toolbar affordances (Cut/Copy/Paste/Undo/Redo), a per-task countdown timer, and a real-time word-count footer. Today the writing screens either don't exist (Summarize Written Text) or are written in a different style (Write Essay with outbox/BLoC pipeline). This spec delivers UI-only mock screens so reviewers can walk the flow before the writing backend lands.

---

## User Stories

- **[P1]** As a test-taker, I want a **Summarize Written Text screen** that shows a passage, a 10-minute countdown, and a one-sentence text editor with a 5-to-75 word target.
  Accepted when: counter visible, toolbar enabled, typing updates word count live, drafting stays across edits, timer hits zero the editor locks.

- **[P1]** As a test-taker, I want a **Write Essay (v2) screen** that shows the prompt, a 20-minute countdown, and a 200-300 word text editor with the same toolbar.
  Accepted when: same affordances as Summarize, min/max bounds surface inline.

- **[P1]** As a test-taker, I want a **shared text-editor toolbar** with Cut / Copy / Paste / Undo / Redo.
  Accepted when: each button reflects the current selection/edit state (Undo disabled when stack empty, etc.) and the underlying TextField receives the result.

- **[P1]** As a test-taker, I want a **countdown timer** showing `MM:SS` that runs against the task's configured duration and locks the editor at zero.
  Accepted when: timer ticks once per second; `00:00` disables the TextField.

- **[P2]** As a reviewer, I want a **dev preview walkthrough** flipping between the two screens (`Summarize Written Text` → `Write Essay`) on `localhost:8080`.
  Accepted when: `flutter run -t lib/dev/writing_preview.dart -d chrome --web-port=8080` boots and the Back/Next buttons swap screens without losing draft state.

- **[P2]** As a developer, I want both screens to reuse the existing `ExamScaffold` frame and consume `AppStrings` / `AppColors` / `AppDimensions` constants (no inline literals).
- **[P3]** _(out of scope) Domain `Question` entity, BLoC, backend scoring, autosave, real submit; outbox wiring is deferred until the writing backend lands._

---

## Functional Requirements

1. **FR-01 (Screens):** Create `SummarizeWrittenTextScreen` + `WriteEssayV2Screen` in `lib/features/exam_attempt/presentation/pages/`. Each is a `StatefulWidget` (UI-only; tracks draft locally via `setState`) — pattern mirrors the existing exam-attempt pages.
2. **FR-02 (Shared header):** Create `WritingTaskHeader` widget combining title + instruction + `CountdownTimer`.
3. **FR-03 (Toolbar):** Create `TextEditorToolbar` with Cut/Copy/Paste/Undo/Redo. Self-managed undo stack capped at 50; disabled state when stacks are empty.
4. **FR-04 (Passage panel):** Create `PassagePanel` — bordered scrollable block that hosts the reading passage or the essay prompt.
5. **FR-05 (Countdown):** Create `CountdownTimer` with injectable `Ticker` for tests; cancels the periodic `Timer` on dispose.
6. **FR-06 (Fixtures):** Mock data in `lib/features/exam_attempt/dev/writing_task_fixtures.dart` — passage, prompt, `min/max` words, durations.
7. **FR-07 (Constants):** New labels/colors/dimensions in `AppStrings`, `AppColors`, `AppDimensions`. No inline strings/colors/numbers.
8. **FR-08 (Dispatcher integration):** Add task-type constants `SUMMARIZE_WRITTEN_TEXT` and `WRITE_ESSAY_V2` (the v2 suffix avoids collision with the existing outbox-backed `WRITE_ESSAY`) and wire both screens into `TaskTypeDispatcher`.
9. **FR-09 (Preview):** `lib/dev/writing_preview.dart` uses `IndexedStack` to flip between the two screens; `IndexedStack` keeps each screen mounted so draft + timer survive flips.
10. **FR-10 (Word count):** Local helper `countWords(text)` (split on whitespace, ignore leading/trailing) called on every keystroke; bounds surface inline; label turns red when out-of-range.

---

## Non-Functional Requirements

- `flutter analyze lib test` = 0 issues.
- Each new `.dart` file ≤ 300 lines; `build()` ≤ 50 lines; `const` where possible.
- `dispose()` cancels any active `Timer.periodic` and disposes every `TextEditingController`.

---

## Success Criteria

- [ ] `SummarizeWrittenTextScreen` renders the passage + editor + word-count footer.
- [ ] `WriteEssayV2Screen` renders the prompt + editor + word-count footer.
- [ ] Toolbar Cut/Copy/Paste/Undo/Redo mutate the editor correctly.
- [ ] Countdown ticks once per second and disables the editor at `00:00`.
- [ ] Word count updates on every keystroke; out-of-range text turns red.
- [ ] `flutter analyze lib test` = 0 issues.
- [ ] `lib/dev/writing_preview.dart` boots; Next/Back walks both screens.
- [ ] Both screens reuse `ExamScaffold` and constants.

---

## Out of Scope

- Domain `Question` entity, BLoC/backend wiring, scoring, autosave, real submit.
- Outbox-backed persistence — a separate task once the writing backend lands.

---

## Assumptions

- Reference is the wide/desktop web layout (consistent with `core_test`/`reading`).
- No new third-party packages — undo/redo self-managed; clipboard interaction deferred to OS shortcuts.

---

## Resolved Decisions

- **Strategy:** UI-only mock screens; outbox wiring deferred.
- **Task-type naming:** `SUMMARIZE_WRITTEN_TEXT` (new) + `WRITE_ESSAY_V2` (suffix avoids colliding with existing `WRITE_ESSAY` outbox screen).
- **Timer source:** injected `Ticker` so widget tests can drive ticks without real time.
- **Toolbar undo stack:** capped at 50 snapshots.
- **Preview:** `IndexedStack` keeps both screens mounted — verified that flipping does not reset draft text.
