import 'package:equatable/equatable.dart';

import 'timer_phase.dart';

/// The shape `TimerService` exposes on every tick/reconciliation.
/// Equatable so `BlocSelector` can skip a rebuild when an unrelated part of
/// `ExamAttemptState` changes but the timer slice itself is unchanged
/// (phase-04 Design Constraints).
class TimerSnapshot extends Equatable {
  const TimerSnapshot({required this.phase, required this.remaining, required this.currentOrderIndex});

  final TimerPhase phase;
  final Duration remaining;
  final int currentOrderIndex;

  @override
  List<Object?> get props => [phase, remaining, currentOrderIndex];
}
