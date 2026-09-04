# pte_app

Flutter exam-taking client for the PTE LMS platform. Offline-resilient,
server-authoritative exam delivery: the exam is the highest-stakes flow on
the platform, so the architecture is built around one rule — **answers are
never lost**, even offline, even if the app is killed mid-exam.

> Flutter only. The web frontend (`pte-web`, Next.js) and backend
> (`pte-api`, Spring Boot) are separate repos — this app shares no code
> or generated types with either.

## Setup

- Dart SDK `^3.11.5` (matches `pubspec.yaml` `environment.sdk`).
- **Windows only:** Enable Windows Developer Mode before running the app on Windows.
  This is required whenever a new native Windows plugin is added (e.g. `just_audio_media_kit`,
  `media_kit_libs_windows_audio`). Without it, `flutter run -d windows` or `flutter build windows`
  fails with "Building with plugins requires symlink support." Enable via
  Settings → Privacy & Security → Developer Settings → Developer Mode (or `ms-settings:developers`).
- `flutter pub get` to install dependencies.
- After any change to a Drift table/schema (`lib/core/storage/`), regenerate
  code:
  ```
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Run tests / lint / format (must all pass before code review):
  ```
  flutter test
  flutter analyze
  dart format lib/ test/ --check
  ```

## Directory Structure

```
pte-app/
├── lib/
│   ├── main.dart              # Entry point — runApp(PteApp()). DI modules are NOT
│   │                          # wired here yet; see "Wiring DI" below before adding the
│   │                          # first real screen.
│   ├── app.dart                # PteApp — MaterialApp shell. Still a placeholder Scaffold;
│   │                            # swap `home:` for a router/first real page when ready.
│   ├── core/                    # Shared infrastructure. NOT a feature — no UI, no
│   │                            # business rules, only services every feature can depend on.
│   │   ├── config/               # AppConfig — API base URL, timeouts. One class, no env-var
│   │   │                         # parsing yet (placeholder defaults).
│   │   ├── network/                # Dio HTTP layer
│   │   │   ├── dio_client.dart        # createDio()/createRefreshDio() — builds configured Dio instances
│   │   │   ├── token_store.dart        # TokenStore interface + InMemoryTokenStore (NOT production-ready)
│   │   │   ├── interceptors/
│   │   │   │   └── token_refresh_interceptor.dart  # Transparent 401 refresh, single in-flight lock
│   │   │   ├── api_exceptions.dart       # Sealed ApiException + mapDioExceptionToApiException()
│   │   │   ├── api_client.dart            # ApiClient — startAttempt/submitAnswers/syncTimer/finishAttempt
│   │   │   ├── models/                     # Skeleton DTOs (fields pending pte-be contract confirmation)
│   │   │   └── network_module.dart           # registerNetworkModule(GetIt, AppConfig)
│   │   ├── storage/                 # Local persistence (Drift/SQLite)
│   │   │   ├── tables/                 # answer_outbox_table.dart — the outbox schema
│   │   │   ├── models/                  # answer_sync_status.dart — pending/synced/failed enum
│   │   │   ├── dao/                       # answer_outbox_dao.dart — upsert/query/markSynced/markFailed/checkpointWal
│   │   │   ├── drift_database.dart          # AppDatabase — WAL mode configured here
│   │   │   └── storage_module.dart            # registerStorageModule(GetIt)
│   │   ├── timer/                    # Monotonic countdown, never wall-clock
│   │   │   ├── timer_service.dart       # TimerService — Stopwatch-driven countdown + server-sync polling
│   │   │   └── timer_module.dart          # registerTimerModule(GetIt)
│   │   └── sync/                      # Background outbox flush
│   │       ├── network_canary.dart       # "online" = last server poll succeeded, not OS connectivity
│   │       ├── sync_engine.dart            # SyncEngine — startSync/stopSync, flush-on-canary-event
│   │       └── sync_module.dart              # registerSyncModule(GetIt)
│   └── features/
│       ├── exam_delivery/              # Main exam delivery feature. See its own README.md.
│       │   ├── domain/entities/           # ExamAttemptState — sealed, no framework imports
│       │   ├── data/repositories/           # ExamAttemptRepository (interface) + impl over ApiClient/DAO
│       │   ├── exam_delivery_module.dart    # registerExamDeliveryModule(GetIt)
│       │   └── presentation/
│       │       ├── bloc/                      # ExamAttemptEvent (sealed) + ExamAttemptBloc
│       │       ├── pages/                      # ExamDeliveryPage — placeholder Scaffold
│       │       └── widgets/                    # ExamAppBar, ExamBottomBar, WordMatchingGrid
│       └── device_check/              # Dev-only device check (mic/sound test). Not wired into production
│           │                           # exam flow; accessible via `/dev/device-check-preview` (debug route)
│           │                           # or `/dev/standalone/device-check` when compiled with DEV_SKIP_AUTH.
│           ├── domain/entities/
│           ├── data/repositories/
│           ├── device_check_module.dart    # registerDeviceCheckModule(GetIt) — currently unused
│           └── presentation/
│               ├── cubit/
│               └── pages/
├── test/unit/                # Mirrors lib/ — one test dir per core/ subfolder + per feature
├── plans/pte-app-architecture/   # (in the pte workspace repo) — plan.md + 6 phase-XX-*.md files,
│                                   # spec.md, and the ADRs/decisions behind this structure
└── pubspec.yaml
```

### `lib/core/` — read this before touching anything here

Each subfolder is a layer with one job, and they only depend on the layer
below them: `storage` and `network` know nothing about each other; `timer`
depends on `network` (to poll); `sync` depends on `storage` + `network` +
`timer`. Nothing in `core/` imports from `features/`. If you find yourself
wanting to import a feature type into `core/`, the type belongs in `core/`
or the dependency direction is backwards — stop and reconsider.

Three invariants the whole sync story rests on — don't break these:

1. **Write-before-network.** Anything the student "does" (answers a
   question) is written to `AnswerOutboxDao` first. Only `SyncEngine`
   talks to the network for that data, asynchronously, later.
2. **Stopwatch, never `DateTime.now()`, for elapsed time.** `TimerService`
   computes countdown from `Stopwatch.elapsedMilliseconds`. A system clock
   change must have zero effect on the displayed time.
3. **Canary ≠ OS connectivity.** `NetworkCanary.available` only fires after
   a real server response (`TimerService.ticks`, which only fires from a
   successful poll) — never from `connectivity_plus`-style OS signals
   alone. If you add a second source of "are we online," it must compose
   with this, not replace it.

### `lib/features/<name>/` — one folder per `pte-be` bounded context

Today only `exam_delivery` is a production feature tied to a `pte-api`
bounded context. Additionally, `device_check` exists as a dev-only feature
for microphone/sound testing, not wired into production flows. Future features
(`auth`, `exam_operations`, `results` — see `pte-api`'s bounded contexts) get
their own folder, each with the same three-layer shape:

```
features/<name>/
├── domain/entities/        # Plain Dart classes/sealed states — no Flutter, no Bloc import
├── data/repositories/        # Interface + impl wrapping core/ services (ApiClient, DAOs)
└── presentation/
    ├── bloc/                    # Sealed Event + Bloc<Event, State>
    ├── pages/                    # Widgets — thin, delegate to the Bloc
    └── <name>_module.dart          # registerXModule(GetIt) — DI wiring for this feature
```

Create a feature folder only when real work on that bounded context starts
— don't pre-scaffold all four up front. `exam_delivery/README.md` is the
worked example to copy the pattern from.

## How to add the next module

**Adding a new `core/` service** (e.g. a future `notifications/` or
`analytics/` layer):

1. New subfolder under `lib/core/`, same shape as the existing ones: the
   service class(es) + a `<name>_module.dart` exporting
   `registerXModule(GetIt getIt)`.
2. If it depends on another core service, take that dependency via
   `getIt<OtherService>()` inside the registration function — never via a
   global/static lookup inside the service class itself (keeps every
   service constructor-injectable and fake-able in tests).
3. Write tests first (`test/unit/<name>/`) using a hand-written fake, not a
   mocking package — every existing test in this repo does it this way
   (`_FakeApiClient extends ApiClient` overriding one method, etc.). Confirm
   red, implement until green.

**Adding a new feature** (e.g. `auth/`):

1. Mirror `exam_delivery/`'s three-layer shape (above).
2. The Bloc depends only on this feature's own `Repository` interface +
   whatever `core/` services it genuinely needs (`SyncEngine`,
   `TimerService`, etc.) — never reaches into another feature's
   `data/`/`domain/` folders.
3. Add `registerXModule(GetIt)` and call it from wherever `main.dart`'s
   bootstrap lives (see below).
4. Write the Bloc's transition tests first, same hand-written-fake
   convention as `exam_attempt_bloc_test.dart`.

## Wiring DI (not done yet — do this before the first real screen)

Every `core/` and `feature/` module currently exposes a
`registerXModule(GetIt)` function, but **nothing calls them yet** —
`main.dart` only does `runApp(const PteApp())`. Before wiring a real
screen to live services, add a bootstrap step, in dependency order:

```dart
final getIt = GetIt.instance;
registerNetworkModule(getIt, const AppConfig());
registerStorageModule(getIt);
registerTimerModule(getIt);
registerSyncModule(getIt);
registerExamDeliveryModule(getIt);
runApp(const PteApp());
```

(`network` and `storage` have no inter-dependency and can register in
either order relative to each other; `timer` needs `network`; `sync` needs
`storage` + `network` + `timer`; each feature module needs its core
dependencies registered first.) Put this in `main.dart` directly or extract
to `lib/bootstrap.dart` once it grows past a few lines.

## Tech Stack

- **Framework:** Flutter, Dart `^3.11.5` (sealed classes, pattern matching)
- **State management:** `flutter_bloc` — sealed-class states/events per
  feature, not parallel Cubits (see `exam_delivery/README.md` for why)
- **Local persistence:** `drift` (SQLite) — WAL mode, outbox pattern
- **HTTP:** `dio`, with a transparent token-refresh interceptor
- **DI:** `get_it` — constructor injection everywhere, no `GetIt.I` calls
  inside service/Bloc classes themselves
- **Testing:** `flutter_test` only — no mocking package; every fake is a
  hand-written subclass overriding the one or two methods a test needs
- **Backend:** `pte-api`/`pte-be` (separate repo) over REST

See `plans/pte-app-architecture/plan.md` (and its `phase-01..06-*.md`
files) for the full rationale and decision history behind this structure,
including the red-team review and the open `pte-be` contract questions
(idempotency-key format, retry semantics) noted in that plan's
pre-implementation checklist.
