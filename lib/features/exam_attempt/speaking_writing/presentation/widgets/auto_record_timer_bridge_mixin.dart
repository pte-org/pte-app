import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';

/// Shared timer-bridge boilerplate for every auto-record speaking screen
/// (Personal Introduction, Read Aloud, Repeat Sentence, Describe Image,
/// Retell Lecture, Answer Short Question, Summarize Group Discussion,
/// Respond to a Situation) — bridges `ExamAttemptBloc`'s
/// clock into an [AutoRecordCubit], the single authoritative source (see
/// `AutoRecordCubit.onTimerSnapshot`'s doc), never a second timer.
///
/// Deliberately does not override [State.initState]/[State.dispose] itself —
/// the concrete screen's own `State` calls [startAutoRecordBridge] and
/// [disposeAutoRecordBridge] explicitly from its own lifecycle methods,
/// matching this codebase's explicit-lifecycle style (no hidden mixin
/// magic).
mixin AutoRecordTimerBridgeMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<ExamAttemptState>? _timerBridgeSubscription;

  /// Seeds from the bloc's current state immediately (covers resuming
  /// mid-task — don't wait for the next ~1s tick), then keeps forwarding
  /// for the screen's lifetime. [audioPromptCubit], when supplied, is
  /// forwarded the same snapshot alongside [cubit] — the 5 Speaking screens
  /// with an audio prompt own both an [AutoRecordCubit] (recording) and an
  /// [AudioPromptCubit] (audio-prompt playback) side by side, driven off
  /// the identical clock (plans/phat-speaking-audio-prompt-e2e).
  void startAutoRecordBridge({
    required TaskView task,
    required AutoRecordCubit cubit,
    AudioPromptCubit? audioPromptCubit,
  }) {
    final bloc = context.read<ExamAttemptBloc>();
    void forward(ExamAttemptState state) => _forwardIfCurrentTask(
      state,
      task: task,
      cubit: cubit,
      audioPromptCubit: audioPromptCubit,
    );
    forward(bloc.state);
    _timerBridgeSubscription = bloc.stream.listen(forward);
  }

  /// Bridges `ExamAttemptBloc`'s clock into the cubit — the single
  /// authoritative source (see `AutoRecordCubit.onTimerSnapshot`'s doc),
  /// never a second timer. Guards on `pinnedItemPublicId` matching this
  /// screen's own task: `TaskTypeDispatcher` defers the outgoing screen's
  /// `dispose()` to end-of-frame while the bloc's next-task emission is
  /// delivered via microtask, so a stale screen's subscription can
  /// otherwise receive the *new* task's first snapshot before its own
  /// teardown runs — reachable via proctor-forced/rejected-submission
  /// advances, which bypass the recorded/upload gate that makes the normal
  /// advance path safe (plan-reviewer CRITICAL finding).
  void _forwardIfCurrentTask(
    ExamAttemptState state, {
    required TaskView task,
    required AutoRecordCubit cubit,
    AudioPromptCubit? audioPromptCubit,
  }) {
    if (state is! AttemptInProgress) return;
    if (state.task.pinnedItemPublicId != task.pinnedItemPublicId) return;
    cubit.onTimerSnapshot(state.timerSnapshot);
    audioPromptCubit?.onTimerSnapshot(state.timerSnapshot);
  }

  void disposeAutoRecordBridge() {
    unawaited(_timerBridgeSubscription?.cancel());
  }
}
