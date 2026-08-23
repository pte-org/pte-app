import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';

sealed class ExamAttemptEvent {
  const ExamAttemptEvent();
}

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
  const NextTaskRequested();
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
