import 'package:flutter_bloc/flutter_bloc.dart';

/// Non-generic seam so a caller that only needs to flush the currently
/// on-screen answer (the shared advance button) doesn't need to know
/// which task type's concrete state shape a cubit carries — Phase 6's
/// `READ_ALOUD` cubit implements the same contract (phase-05 Steps).
abstract class FlushableAnswerCubit {
  /// Cancels any pending debounce and performs one final synchronous local
  /// upsert so the very latest edit isn't lost to an in-flight debounce
  /// window, before the caller flushes the row over the network.
  Future<void> flushPendingEdit();
}

abstract class TaskAnswerCubit<S> extends Cubit<S> implements FlushableAnswerCubit {
  TaskAnswerCubit(super.initialState);
}
