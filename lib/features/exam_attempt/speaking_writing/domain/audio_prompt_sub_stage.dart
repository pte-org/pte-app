import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';

/// How much of the shared `prep` window has elapsed, clamped to
/// `[0, task.prepSeconds]` — once `response` begins (or the task is
/// recorded), prep is by definition fully elapsed, which is exactly what
/// [AudioListeningPrepCard] needs to render its final ("audio finished")
/// state without any extra phase branching. Pure domain arithmetic —
/// extracted out of `audio_prompt_record_body.dart` (plans/phat-speaking-
/// audio-prompt-e2e) so `AudioPromptCubit` can reuse it without a cubit
/// importing a widget file; that widget file re-exports this one, so
/// nothing already depending on it there needs to change.
int elapsedPrepSeconds(TaskView task, TimerSnapshot? snapshot) {
  if (snapshot == null) return 0;
  if (snapshot.phase == TimerPhase.response) return task.prepSeconds;
  return (task.prepSeconds - snapshot.remaining.inSeconds).clamp(
    0,
    task.prepSeconds,
  );
}

/// Whether the shared `prep` window's "Playing" (audio) sub-stage is
/// currently active — the same boundary `AudioListeningPrepCard` itself
/// switches its label on. `AudioPromptCubit` uses this to trigger its one
/// real `/audio` call+play at the same boundary.
bool isAudioPlayingSubStage(
  TaskView task,
  TimerSnapshot? snapshot, {
  required int preListenSeconds,
  required int preRecordSeconds,
}) {
  final elapsed = elapsedPrepSeconds(task, snapshot);
  if (elapsed < preListenSeconds) return false;
  final preRecordStart = (task.prepSeconds - preRecordSeconds).clamp(0, task.prepSeconds);
  return elapsed < preRecordStart;
}
