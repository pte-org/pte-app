# Phase 2: Summarize Written Text screen

**Covers:** P1 SWT · **Depends on:** Phase 1 · **Testing:** default

---

## Outcome

`SummarizeWrittenTextScreen` exists in `lib/features/exam_attempt/presentation/pages/summarize_written_text_screen.dart` (142 lines) and renders the passage + editor + countdown + word-count footer inside `ExamScaffold`.

## Tasks

### 1. Constructor + state
- Takes only `task: TaskView` (UI-only — no `outboxDao`/`syncEngine` to keep the screen mockable without a real `AppDatabase`).
- State: `TextEditingController _controller`, local `int _wordCount`, `bool _timeExpired`.

### 2. Wire shared widgets
- Header: `WritingTaskHeader(title: AppStrings.summarizeWrittenTextTitle, instruction: AppStrings.summarizeWrittenTextInstruction, totalSeconds: kSummarizeWrittenTextDurationSeconds, onTimeExpired: _handleTimeExpired)`.
- Passage: `PassagePanel(body: _passage)` — falls back to `kSummarizeWrittenTextPassage` when `task.promptText` is empty.
- Editor box: `TextEditorToolbar(controller: _controller)` above `TextField(maxLines: null, expands: true, enabled: !_timeExpired)`.
- Footer: `_SummarizeWordCountFooter` — local consumer of `_wordCount` (read out of `setState`), bounds from `task.minWordCount` / fallback `kSummarizeWrittenTextMinWords`.

### 3. Word-count update path
- `_controller.addListener(_onDraftChanged)` in `initState`; on edit recompute via `text.trim().split(RegExp(r'\s+')).length`.
- `dispose()` calls `_controller.dispose()`.

### 4. Time-expired path
- `_handleTimeExpired` flips `_timeExpired = true` (after `if (!mounted) return;`) which disables the TextField and turns the footer red when out-of-range.

### 5. Sub-widgets (private file-local classes)
- `_EditorBox` (extracts the toolbar + TextField from the page's `build()` so `build()` stays ≤ 50 lines).
- `_SummarizeWordCountFooter` (extracts the footer and its bounds logic).

## Acceptance criteria
- [x] `build()` of `SummarizeWrittenTextScreen` ≤ 50 lines.
- [x] File ≤ 300 lines.
- [x] Reuses `WritingTaskHeader`, `TextEditorToolbar`, `PassagePanel`, `CountdownTimer`.
- [x] Editor locks at `00:00`; word-count label turns red when out-of-range and timer expired.

## Test (default)
Pending — `summarize_written_text_screen_test.dart` next session.
