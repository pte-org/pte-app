# Phase 3: Write Essay (v2) screen + dev preview + dispatcher wiring

**Covers:** P1 WE, P2 preview · **Depends on:** Phase 1, Phase 2 · **Testing:** default

---

## Outcome

`WriteEssayV2Screen` exists in `lib/features/exam_attempt/presentation/pages/write_essay_v2_screen.dart` (128 lines); dev walkthrough `lib/dev/writing_preview.dart` boots both screens; both tasks route through `TaskTypeDispatcher`.

## Tasks

### 1. `WriteEssayV2Screen` constructor
- Same UI-only `setState` pattern as `SummarizeWrittenTextScreen` (no `outboxDao`/`syncEngine` — the existing `WriteEssayScreen` keeps its outbox pipeline).
- State: `_controller`, `_wordCount`, `_timeExpired`. `dispose()` cancels the controller.
- Word bounds: defaults to `kWriteEssayMinWords = '200'` / `kWriteEssayMaxWords = '300'` (parsed via `int.parse`), overridable from `task.minWordCount` / `task.maxWordCount`.

### 2. Shared widgets wired
- `WritingTaskHeader(title: AppStrings.writeEssayV2Title, instruction: AppStrings.writeEssayV2Instruction, totalSeconds: kWriteEssayDurationSeconds)`.
- `PassagePanel(body: _prompt)` — falls back to `kWriteEssayPrompt`.
- `TextEditorToolbar` above the TextField; footer `_WordCountFooter` (private).

### 3. Dispatcher integration (`lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`)
- New task-type constants: `_taskTypeSummarizeWrittenText = 'SUMMARIZE_WRITTEN_TEXT'`, `_taskTypeWriteEssayV2 = 'WRITE_ESSAY_V2'`.
- Two new arms in the `switch (task.taskType)` expression:
  - `SummarizeWrittenTextScreen(key: key, task: task)`
  - `WriteEssayV2Screen(key: key, task: task)`

### 4. Dev preview (`lib/dev/writing_preview.dart`, 95 lines)
- `Scaffold` + `AppBar` + `IndexedStack` containing both screens so drafts/timers survive Back/Next flips.
- Builds minimal `TaskView` fixtures with the right `pinnedItemPublicId` / `section` / `taskType` / `promptText` / `minWordCount` / `maxWordCount` / `responseSeconds`.
- Back button on `_index == 0`, forward button on `_index == _entries.length - 1` are disabled.
- Run via: `flutter run -t lib/dev/writing_preview.dart -d chrome --web-port=8080`.

## Acceptance criteria
- [x] `build()` of `WriteEssayV2Screen` ≤ 50 lines (page ≤ 128 lines).
- [x] Reuses all Phase-1 widgets.
- [x] `TaskTypeDispatcher` recognizes `SUMMARIZE_WRITTEN_TEXT` and `WRITE_ESSAY_V2` without affecting existing branches.
- [x] Preview mounts both screens; Next/Back does not lose draft text.

## Test (default)
- `write_essay_v2_screen_test.dart` pending next session.
- `writing_preview_test.dart` pending next session — would assert both screens render with the IndexedStack.
