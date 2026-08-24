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
  /// **Mock** — `TimerService.mockExamTotalDuration` is a hardcoded
  /// constant anchored to whenever this `TimerService` instance first
  /// started seeding a task, not a real backend value: no API response
  /// this app consumes exposes `ExamAttempt.startedAt` or a total-exam-
  /// duration field yet. Defaults to `Duration.zero` so every `TimerSnapshot`
  /// built before this field existed (most tests) keeps compiling unchanged.
  final Duration examRemaining;

  @override
  List<Object?> get props => [phase, remaining, currentOrderIndex, examRemaining];
}
