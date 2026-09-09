import 'package:equatable/equatable.dart';

import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';

/// The shape `TimerService` exposes on every tick/reconciliation.
/// Equatable so `BlocSelector` can skip a rebuild when an unrelated part of
/// `ExamAttemptState` changes but the timer slice itself is unchanged
/// (phase-04 Design Constraints).
class TimerSnapshot extends Equatable {
  const TimerSnapshot({
    required this.phase,
    required this.remaining,
    required this.currentOrderIndex,
    this.examRemaining = Duration.zero,
  });

  final TimerPhase phase;
  final Duration remaining;
  final int currentOrderIndex;

  /// Countdown for the whole exam, shown in `ExamAppBar`'s "Time Remaining".
  /// Derived from the server-provided `TaskView.examEndTime`
  /// (`ExamAttempt.startedAt` plus the pinned snapshot's total
  /// `prepSeconds + responseSeconds`), recomputed on every seed. Defaults to
  /// `Duration.zero` before the first one, or for an attempt predating the
  /// backend field.
  final Duration examRemaining;

  @override
  List<Object?> get props => [phase, remaining, currentOrderIndex, examRemaining];
}
