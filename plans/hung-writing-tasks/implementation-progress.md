# Writing Tasks: App Integration Progress

**Updated:** 2026-09-06
**Scope:** Connect production Writing task screens to the existing local answer outbox and synchronization pipeline, while keeping the Chrome preview independent of storage dependencies.

## Change History

### 2026-09-05 — Production Writing persistence

- `SummarizeWrittenTextBody` and `WriteEssayV2Body` now accept an optional `persistDraft` callback. They no longer access Cubit, outbox, sync, or `BuildContext` persistence dependencies directly.
- `SummarizeWrittenTextScreen` and `WriteEssayV2Screen` create `WriteEssayCubit` with `attemptPublicId` and `pinnedItemPublicId`, pass `draftChanged` into the body callback, and use `TaskAdvanceButton` to flush and synchronize the current answer before moving to the next task.
- `TaskTypeDispatcher` maps backend task type `WRITE_ESSAY` to the persisted essay screen and passes production dependencies to both Writing screens. Invalid backend task type `WRITE_ESSAY_V2` was removed from the production dispatcher.
- The Chrome-only preview still mounts the two body widgets directly. Its preview task can retain mock-only naming because it bypasses the production dispatcher.
- Writing headers now use `TaskView.responseSeconds` supplied by the server-pinned task rather than fixture constants, so task-composition timing overrides remain accurate in the UI.

## Review outcome — 2026-09-06

### Confirmed complete: delivery and answer submission

- Authoring recognizes `SUMMARIZE_WRITTEN_TEXT` and `WRITE_ESSAY` as Writing task types with prompt text and response word-count bounds.
- Exam Delivery pins and returns each task's word-count bounds and response time: 600 seconds for `SUMMARIZE_WRITTEN_TEXT` and 1,200 seconds for `WRITE_ESSAY`.
- The production Flutter dispatcher routes both backend task-type values to persisted screens. Each screen writes drafts to the local answer outbox and `TaskAdvanceButton` flushes that row through `SyncEngine` before the attempt advances.
- `SyncEngine` submits the raw text payload to `POST /api/exam-delivery/attempts/{attemptPublicId}/answers` with the active pinned-item identifier.
- Backend mapper verification passed on 2026-09-06: `./mvnw.cmd -pl services/exam-delivery -Dtest=AttemptMapperTest test` — 9 tests passed.

### Not complete: scoring and production readiness

- `SUMMARIZE_WRITTEN_TEXT` has no scoring dispatch path. The scoring service only treats `READ_ALOUD` and `WRITE_ESSAY` as AI-scorable; a submitted summarize response remains `PENDING` and blocks a fully scored attempt.
- `WRITE_ESSAY` is sent to the essay scoring worker, but the current workflow deliberately ends at `AI_SCORED_PENDING_REVIEW`; a host must approve it before an `AnswerScored` event and final attempt scoring occur.
- The writing screens start their local countdown from `TaskView.responseSeconds`, not the server-provided remaining time derived from `responseDeadline` and `serverNow`. An attempt resumed during a response window can therefore display more time than the server allows; the server remains authoritative and can reject an expired submission.
- The configured 600- and 1,200-second durations are marked as approximate placeholders in Exam Delivery configuration and require confirmation against the official PTE requirements before release.

### Decision

The API connection is complete for **displaying, drafting, persisting, and submitting** responses for both Writing tasks. It is **not complete end-to-end**: implement scoring for `SUMMARIZE_WRITTEN_TEXT`, resolve the server-clock countdown behavior, and complete the verification items below before describing the feature as production-ready.
## Verification

- `flutter analyze` was attempted on 2026-09-05 but cannot run in the current environment because the Flutter CLI is not installed or not available on `PATH`.
- `git diff --check` passed after the final app changes.
- Existing `WriteEssayCubit` unit tests cover debounced persistence, immediate flush, word counting, and verbatim payload behavior, but have not been executed in the current environment.
- Existing dispatcher tests do not cover the newly changed `WRITE_ESSAY` and `SUMMARIZE_WRITTEN_TEXT` production routes.
- No Flutter-to-backend end-to-end run has verified RabbitMQ delivery, answer ingestion, essay-scoring behavior, host-review completion, or resuming a writing task during its server response window.

## Required follow-up

- [ ] Add `SUMMARIZE_WRITTEN_TEXT` to the appropriate scoring workflow, including status-transition and attempt-completion tests.
- [ ] Make Writing countdowns derive their initial remaining duration from `TaskView.responseDeadline` and `TaskView.serverNow`, and add a resume-window test.
- [ ] Confirm the official PTE response durations and replace the documented placeholder configuration where necessary.
- [ ] Run `flutter analyze` from a Flutter SDK environment.
- [ ] Run `flutter test test/unit/features/exam_attempt/write_essay_cubit_test.dart`.
- [ ] Add and run dispatcher tests for `WRITE_ESSAY` and `SUMMARIZE_WRITTEN_TEXT`.
- [ ] Manually exercise both tasks using the bootstrap data in `pte-api/plans/hung-writing-tasks/bootstrap-writing-e2e.ps1`, including answer submission, scoring event handling, and host review for Write Essay.
