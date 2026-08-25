import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';

sealed class ExamAttemptEvent {
  const ExamAttemptEvent();
}

/// Why a task advanced — carried through to [AttemptCompleted] so the UI can
/// show "Time is up" instead of the normal completion message when the
/// section ended because its shared countdown hit zero, not because the
/// student answered the last task (phase-08 auto time's-up).
enum AdvanceReason { manual, timeExpired }

/// Resolves [rawInput] into a session ID via `SessionEntryRepository`,
/// then starts or resumes the attempt for it. `rawInput`'s meaning is
/// entirely owned by whichever `SessionEntryRepository` is registered
/// (raw manual text today; a deep-link URI or a picked list item's ID
/// later) — this event only carries it through untouched.
final class SessionResolutionRequested extends ExamAttemptEvent {
  const SessionResolutionRequested({required this.rawInput});

  final String rawInput;
}

/// Advances to the next task for the currently running attempt. A no-op
/// (not a crash) if dispatched with no attempt running — e.g. a stray
/// event arriving after `AttemptCompleted` (phase-03 Design Constraints).
final class NextTaskRequested extends ExamAttemptEvent {
  const NextTaskRequested({this.reason = AdvanceReason.manual});

  final AdvanceReason reason;

  // Value equality (rather than the default identity) so a `NextTaskRequested`
  // built at runtime with an explicit `reason:` (as `TaskAdvanceButton._advance`
  // always does, including for the default reason) compares equal to a
  // `const NextTaskRequested()` literal with the same reason — mocktail's
  // `verify` and bloc_test's `expectLater(bloc, emits(...))` both rely on `==`.
  @override
  bool operator ==(Object other) => other is NextTaskRequested && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Dispatched internally by the `TimerService.ticks` subscription — not
/// intended to be dispatched by UI code directly.
final class TimerSnapshotUpdated extends ExamAttemptEvent {
  const TimerSnapshotUpdated(this.snapshot);

  final TimerSnapshot snapshot;
}

/// Dispatched internally when a timer poll detects `currentOrderIndex`
/// changed without the client itself having requested `next-task` (e.g. a
/// proctor-initiated advance) — triggers the same task refresh path as
/// [NextTaskRequested] rather than continuing to display a countdown for a
/// task that is no longer current (phase-04 Design Constraints).
final class TimerTaskAdvancedExternally extends ExamAttemptEvent {
  const TimerTaskAdvancedExternally();
}

/// Dispatched internally when `SyncEngine` discovers (via a background
/// flush) that the currently-displayed task was already rejected as
/// stale/expired by the server — triggers the same task refresh path as
/// [TimerTaskAdvancedExternally], since the client's local "current task"
/// view is equally stale here (phase-07 Design Constraints).
final class SyncTaskRejectedExternally extends ExamAttemptEvent {
  const SyncTaskRejectedExternally();
}

/// User-initiated, irreversible: ends the attempt immediately regardless of
/// remaining tasks via `POST .../submit`. UI dispatches this only after an
/// explicit confirmation step (phase-07 Design Constraints).
final class ForceSubmitRequested extends ExamAttemptEvent {
  const ForceSubmitRequested();
}

/// `kDebugMode`-only: seeds [task] straight into `AttemptInProgress` without
/// any repository/network call, so a dev-preview screen (e.g.
/// `SpeakingWritingTaskPreviewScreen`) can drive `AutoRecordTimerBridgeMixin`'s
/// live countdown off a fixture. Mirrors `_emitFromResponse`'s in-progress
/// branch (`TimerService.seedFromTask` + `startPolling`) but skips the
/// `completed`/`task == null` branches that only apply to a real server
/// response — never dispatched outside dev-preview tooling
/// (phat-speaking-audio-verify plan.md Phase 2).
final class DevPreviewAttemptSeeded extends ExamAttemptEvent {
  const DevPreviewAttemptSeeded(this.task);

  final TaskView task;
}

/// Dispatched by `ExamScaffold`'s `WidgetsBindingObserver` when the app
/// transitions back to `AppLifecycleState.resumed` — forces an immediate
/// timer re-poll rather than waiting up to the normal poll interval, since
/// the OS may have suspended/throttled the app (and its `Stopwatch`-driven
/// local countdown) for an unknown stretch while backgrounded. A no-op if no
/// attempt is running.
final class AppResumed extends ExamAttemptEvent {
  const AppResumed();
}
