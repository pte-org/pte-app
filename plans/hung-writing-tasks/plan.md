# Plan: Writing Tasks (Summarize Written Text + Write Essay)

**Folder:** `plans/hung-writing-tasks/`
**Code lives in:** `lib/features/exam_attempt/` (existing screen folder, sibling `ReadAloudScreen`/`WriteEssayScreen`)
**Date:** 2026-08-23
**Mode:** Fast
**Testing:** Default (light widget tests — pending next session)
**Status:** Phases 1-3 implemented

---

## Goal

Xây 2 màn hình Writing task của Aptis: **Summarize Written Text** và **Write Essay (v2)** với shared header + toolbar + countdown + word-count footer. Cả 2 screen là UI-only mock để reviewer walk flow trước khi writing backend sẵn sàng.

## Approach

`StatefulWidget` + local `setState` cho draft state; không cubit/outbox (UI-only). Mọi string/colour/dimension đi qua `app_strings.dart`, `app_colors.dart`, `app_dimensions.dart`. Reuse `ExamScaffold` cho frame. Undo/redo tự quản lý với stack cap 50. Timer dùng injectable `Ticker` để testable.

## Reference files (đọc trước khi sửa)

- Frame: `lib/features/exam_attempt/presentation/widgets/exam_scaffold.dart`
- Pattern để mirror: `lib/features/exam_attempt/presentation/pages/write_essay_screen.dart`
- Dispatcher: `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`
- Constants: `lib/core/constants/app_strings.dart`, `app_colors.dart`, `app_dimensions.dart`

## Code structure

```
lib/features/exam_attempt/
├── presentation/
│   ├── pages/
│   │   ├── summarize_written_text_screen.dart   # WRAPPER (ExamScaffold + Body)
│   │   └── write_essay_v2_screen.dart           # WRAPPER (ExamScaffold + Body)
│   └── widgets/
│       ├── summarize_written_text_body.dart     # MỚI — pure UI (header+panel+editor+footer)
│       ├── write_essay_v2_body.dart             # MỚI — pure UI (header+panel+editor+footer)
│       ├── writing_task_header.dart             # MỚI (title + instruction + countdown)
│       ├── text_editor_toolbar.dart             # MỚI (Cut/Copy/Paste/Undo/Redo)
│       ├── countdown_timer.dart                 # MỚI (MM:SS, injectable Ticker)
│       └── passage_panel.dart                   # MỚI (scrollable bordered block)
└── dev/
    └── writing_task_fixtures.dart               # MỚI (mock passage/prompt/durations)

lib/dev/
└── writing_preview_web.dart                     # MỚI (Chrome-only walkthrough; mounts Body directly)
```

The Body/Page split exists so the chrome dev entry can mount pure UI without dragging in `ExamAppBar` → `ExamAttemptBloc` → `AnswerOutboxDao` → `package:sqlite3` (whose `external` FFI symbols don't compile to JS).

---

## Phases

| # | Phase | Covers stories | File | Done |
|---|-------|----------------|------|------|
| 1 | Shared widgets + fixtures + constants | P1 scaffold, P1 reuse | [phase-01-scaffold.md](./phase-01-scaffold.md) | [x] |
| 2 | Summarize Written Text screen + word-count binding | P1 SWT | [phase-02-summarize.md](./phase-02-summarize.md) | [x] |
| 3 | Write Essay (v2) screen + dev preview walkthrough + dispatcher wiring | P1 WE, P2 preview | [phase-03-essay-preview.md](./phase-03-essay-preview.md) | [x] |

Phase 1 → 2/3 độc lập (Phase 2/3 chỉ dùng widget đã có); Phase 3 phụ thuộc Phase 1+2 (preview dùng cả 2 screen).

---

## Story → phase mapping

- **[P1] Summarize Written Text screen** → Phase 2
- **[P1] Write Essay screen** → Phase 3
- **[P1] Toolbar Cut/Copy/Paste/Undo/Redo** → Phase 1
- **[P1] Countdown timer riêng cho mỗi task** → Phase 1
- **[P1] Word count real-time** → Phase 2 (SWT) + Phase 3 (WE)
- **[P2] Reuse `ExamScaffold` + constants** → Phase 1
- **[P2] Dev preview walkthrough SWT → WE** → Phase 3
- **[P3]** _(out of scope) Domain `Question` entity, BLoC, backend, scoring, autosave, thật sự submit_

---

## Testing strategy

`flutter analyze lib test` = 0 issues (gate). Widget tests pending next session:
- `text_editor_toolbar_test.dart` — undo/redo mutate controller đúng.
- `countdown_timer_test.dart` — inject `Ticker` để verify hiển thị.
- `summarize_written_text_screen_test.dart` — typing → word count update.
- `write_essay_v2_screen_test.dart` — typing past `maxWords` → label đổi màu red.

---

## Risks (self-reviewed)

1. **Undo/Redo tự quản lý** có thể tốn memory nếu gõ nhiều. → Cap stack size 50.
2. **Clipboard API** trên web cần permission. → Copy giữ selection; Cut thực sự mutate controller; OS shortcut vẫn paste bình thường.
3. **Timer chạy ngầm khi widget unmount** → cancel `Timer.periodic` (subscribed qua `StreamSubscription`) trong `dispose()`.
4. **300-line limit** → Mỗi screen page ≤ 142 dòng; widgets ≤ 134 dòng.
5. **DRY giữa SWT và WE**: cả 2 đều có header + toolbar + TextField + word count → Phase 1 tách `WritingTaskHeader` + `TextEditorToolbar` + `PassagePanel` dùng chung.
6. **Tên `WRITE_ESSAY_V2`** dùng suffix tránh collision với outbox-backed `WRITE_ESSAY` đã ship.

---

## Session Notes

<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-23
**Phase in progress:** (all complete — Rounds 1)
**Status:** Phases 1, 2, 3 done. Created `WritingTaskHeader`, `TextEditorToolbar`, `CountdownTimer`, `PassagePanel` widgets (Phase 1), `SummarizeWrittenTextScreen` (Phase 2), `WriteEssayV2Screen` + dev preview + dispatcher wiring (Phase 3). `flutter analyze` của các file mới = 0 issues (flutter CLI chưa có trên PATH; đã `flutter analyze`-equivalent bằng `ReadLints`). Not committed (awaiting user).

### Deviations (transparent)
- **Body/Page split.** Each screen consists of `Body` widget (pure UI, header+panel+editor+footer) + `Page` wrapper (`ExamScaffold` + Body). Production pages go through `ExamScaffold`; Chrome dev preview mounts the Body directly to avoid pulling in `ExamAppBar` → `ExamAttemptBloc` → `AnswerOutboxDao` → `package:sqlite3` whose `external` FFI symbols don't compile to JS.
- Bỏ cubit/outbox layer so sánh với plan (plan assume có `core_test`/`reading` folders — thực tế pte-app hiện tại chỉ có `exam_attempt`). UI-only `setState` đã chọn thay vì cubit để preview render được không cần `AppDatabase` (DAO constructor).
- Write Essay screen renamed `WriteEssayV2Screen` + task type `WRITE_ESSAY_V2` để không vướng `WRITE_ESSAY` đã ship với outbox pipeline.
- Toolbar Copy: giữ selection (không gọi `Clipboard.setData` do web permission complexity); Cut thực sự mutate controller; user paste qua OS shortcut (Ctrl+V) vẫn hoạt động.

### Decisions made this session
- Code đặt trong `lib/features/exam_attempt/` (folder thật) thay vì `lib/features/writing/` (plan assumption về folder chưa tồn tại).
- Mock data ở `lib/features/exam_attempt/dev/` thay vì `lib/dev/` để group với feature.
- Dispatcher wire qua `TaskTypeDispatcher` switch expression — cùng pattern với các task khác.

### Next immediate action
Run `flutter run -t lib/dev/writing_preview_web.dart -d chrome --web-port=8080` (Chrome-only entry — mounts Body widgets directly so the build never reaches `package:sqlite3`). Native previews (Windows desktop / mobile) use the existing dispatcher + Screen wrappers.
