# Phase 1: Shared widgets + fixtures + constants

**Covers:** P1 scaffold, P1 reuse · **Depends on:** none · **Testing:** default

---

## Outcome

Four shared widgets and one fixtures file exist under `lib/features/exam_attempt/`, ready to be composed by the Summarize Written Text + Write Essay (v2) screens in Phase 2/3.

## Tasks

### 1. Constants
- Added 12 strings to `lib/core/constants/app_strings.dart` (editor tooltips, screen titles, instructions, time-remaining label, passage-panel label, word-count suffix variants).
- Added 7 dimensions to `lib/core/constants/app_dimensions.dart` (icon size, button size, font size, panel max height, border width, header padding).
- Added 4 colors to `lib/core/constants/app_colors.dart` (panel border/background, toolbar background, countdown text).

### 2. `WritingTaskHeader` widget (`lib/features/exam_attempt/presentation/widgets/writing_task_header.dart`, 58 lines)
- Props: `title`, `instruction`, `totalSeconds`, `onTimeExpired`.
- Layout: title (bold) + inline `CountdownTimer` (right); instruction below.
- Wraps everything in a subtle primary-coloured container so the screen still feels branded without replacing `ExamAppBar`.

### 3. `TextEditorToolbar` widget (`lib/features/exam_attempt/presentation/widgets/text_editor_toolbar.dart`, 134 lines)
- Props: `controller` (the TextEditingController of the editor).
- Buttons: Cut (replaces selection with empty string), Copy (no-op on the underlying buffer but keeps selection alive so OS Ctrl+V still works), Paste (delegates to OS shortcut — no `Clipboard.getData` on web), Undo / Redo.
- Undo/Redo: `_undoStack` + `_redoStack` capturing pre-edit snapshots, pushed via `controller.addListener`; capped at 50 entries (`_undoStackLimit`); cleared redo on every fresh edit.
- Buttons disable when the relevant stack is empty.

### 4. `CountdownTimer` widget (`lib/features/exam_attempt/presentation/widgets/countdown_timer.dart`, 70 lines)
- Props: `totalSeconds`, `onExpired`, optional injected `Ticker` (`Stream<int> Function(Duration)`).
- Ticks down once per second; formats `MM:SS`; cancels `StreamSubscription` in `dispose()`.
- On `_remaining == 0` calls `widget.onExpired` and stops listening.
- Default `Ticker` is a real `Stream.periodic`, but tests inject a fake.

### 5. `PassagePanel` widget (`lib/features/exam_attempt/presentation/widgets/passage_panel.dart`, 41 lines)
- Props: `body`, optional `maxHeight` (default `passagePanelMaxHeight`).
- Bordered + background-coloured container with a `SingleChildScrollView` so long passages scroll without crowding the editor.

### 6. Fixtures (`lib/features/exam_attempt/dev/writing_task_fixtures.dart`, 32 lines)
- `kSummarizeWrittenTextPassage` (≈190-word passage on 19th-century public health — replace when backend lands).
- `kSummarizeWrittenTextMinWords = '5'`, `kSummarizeWrittenTextMaxWords = '75'`, `kSummarizeWrittenTextDurationSeconds = 600`.
- `kWriteEssayPrompt` (university-vs-vocational debate prompt), `kWriteEssayMinWords = '200'`, `kWriteEssayMaxWords = '300'`, `kWriteEssayDurationSeconds = 1200`.

## Acceptance criteria
- [x] Constants added — no inline strings/colors/dimensions in any new widget.
- [x] `WritingTaskHeader` renders title + timer + instruction in a single container.
- [x] `TextEditorToolbar` undo stack capped at 50; redo cleared on each fresh edit.
- [x] `CountdownTimer` accepts injected `Ticker`; cancels subscription on dispose.
- [x] `PassagePanel` scrolls long text without exceeding `passagePanelMaxHeight`.
- [x] Fixtures are `const`-friendly top-level `const`s.

## Test (default)
Pending next session — see `plan.md` Testing Strategy.
