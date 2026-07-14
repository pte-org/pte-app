# exam_delivery

Owns the in-progress exam-taking flow: loading an attempt, accepting
answers, tracking the timer/sync status, and submitting. This is the
foundation layer (Phase 6 of `plans/aptis-app-architecture/`) — full exam
UI (question rendering, navigation, part transitions, timer display) is
future work built on top of this Bloc.

## Why a sealed-class Bloc, not parallel Cubits

The real state space is a cross-product of orthogonal concerns:
connectivity (online/offline) × sync phase (idle/flushing) × part status ×
per-question answer status. A single `flutter_bloc` `Bloc<ExamAttemptEvent,
ExamAttemptState>` backed by a Dart 3 `sealed class` makes every
transition exhaustiveness-checked by the analyzer — missing a state branch
is a compile error, not a silent bug. That matters here because the exam
domain cannot tolerate an unhandled combination going unnoticed.

States (`domain/entities/exam_attempt_state.dart`):
`Loading` → `InProgress` ⇄ `Offline` ⇄ `Syncing` → `Submitted`, with `Error`
reachable from any active state on an unrecoverable failure (e.g. 409 on
submit).

## Event flow

| Event | Effect |
|---|---|
| `StartExamAttemptEvent` | Loads the attempt via `ExamAttemptRepository.startAttempt`, calls `SyncEngine.startSync(attemptId)`, emits `InProgress`. |
| `AnswerQuestionEvent` | Writes to the outbox DAO **first** (via the repository), before anything else — "answered = saved" holds even offline (FR-03). Then increments the local pending counter. |
| `TimerTickEvent` | Forwarded from `TimerService.ticks` (Phase 4) — updates `timeRemaining` only. |
| `SyncStatusChangedEvent` | Updates pending/failed answer counters shown in the UI. |
| `ConnectivityChangedEvent` | Forwarded from the network canary (Phase 5) — toggles `InProgress` ⇄ `Offline`. Never blocks `AnswerQuestionEvent`. |
| `FinishPartEvent` | Skeleton no-op — see Known Gaps. |
| `SubmitExamEvent` | Calls `ExamAttemptRepository.finishAttempt`. On success, **`SyncEngine.stopSync()` runs before `Submitted` is emitted** — there's no point flushing answers for an attempt the server already closed. On 409, emits `Error` instead. |

## Service contracts (core/ dependencies)

`ExamAttemptBloc` depends on exactly two things, both injected via
`get_it` in `exam_delivery_module.dart`:

- `ExamAttemptRepository` (this feature's own thin wrapper over
  `ApiClient` + `AnswerOutboxDao` — `data/repositories/`) — so the Bloc
  doesn't import Dio/Drift types directly, and tests fake one small
  interface instead of two core services.
- `SyncEngine` (Phase 5, `core/sync/`) — only `startSync`/`stopSync` are
  called; the Bloc never reaches into outbox rows or the canary directly.

No `GetIt.I` calls happen inside the Bloc itself — every dependency is a
constructor parameter, so the Bloc is testable with hand-written fakes
(see `test/unit/features/exam_delivery/exam_attempt_bloc_test.dart`) and
has no hidden coupling to the DI container.

## Submit-then-stop ordering, and why it's tested twice

`SyncEngine.startSync()` already throws if called again for a *different*
attemptId while one is running (Phase 5's reentry guard, tested in
`test/unit/sync/sync_engine_test.dart`). That guard is **necessary but not
sufficient**: it only catches a *second* attempt starting before the first
stopped. It does nothing to guarantee the first attempt's sync engine is
ever stopped in the first place. The Bloc-level discipline — call
`stopSync()` synchronously, before emitting `Submitted`, in the same
handler — is the complement that closes that gap. This ordering is
directly asserted in this feature's own test suite (not just relied upon).

## Known gaps (explicitly deferred, not silently missing)

- **`FinishPartEvent` does not advance `currentPartId`.** Multi-part
  progression is real exam UI logic, out of scope for a skeleton phase.
- **No state snapshot survives a force-kill.** The outbox (Phase 2)
  persists buffered answers across restarts, but not which part/screen the
  student was on — reopening always re-fetches attempt state from the
  server via a fresh `Loading` → `StartExamAttemptEvent`. Full
  state-snapshot persistence is future work if product requires exact
  resume.
- **No retry ceiling/backoff is implemented at the Bloc level.** Transient
  submit failures rely entirely on the outbox + sync engine's existing
  "leave pending, retry on next canary event" behavior (Phase 5).

## File ownership

This feature owns everything under `lib/features/exam_delivery/` and its
matching `test/unit/features/exam_delivery/` tests. It does not own
`lib/core/` (Phases 2–5) or other features (`auth/`, `exam_operations/`,
`results/` — future work).
