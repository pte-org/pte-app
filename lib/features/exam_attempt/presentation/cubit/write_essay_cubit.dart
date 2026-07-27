import 'dart:async';

import '../../../../core/storage/dao/answer_outbox_dao.dart';
import 'task_answer_cubit.dart';
import 'write_essay_state.dart';

/// Schedules a one-shot debounce callback. Production uses [Timer.new];
/// tests inject a fake that captures the [Duration] and lets the test
/// manually invoke the callback instead of waiting real time — same
/// pattern `TimerService`'s `TimerScheduler` uses (phase-05 Design
/// Constraints).
typedef DebounceScheduler = Timer Function(Duration duration, void Function() callback);

const Duration _defaultDebounce = Duration(milliseconds: 500);

/// Restarts a debounce timer on every keystroke and writes to the local
/// outbox only on quiet-period expiry — purely for kill-safety (Phase 2's
/// process-death survival), never to trigger a network call by itself
/// (phase-05 Design Constraints).
class WriteEssayCubit extends TaskAnswerCubit<WriteEssayState> {
  WriteEssayCubit({
    required AnswerOutboxDao outboxDao,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    Duration debounce = _defaultDebounce,
    DebounceScheduler? scheduler,
  }) : _outboxDao = outboxDao,
       _debounce = debounce,
       _scheduler = scheduler ?? Timer.new,
       super(const WriteEssayState());

  final AnswerOutboxDao _outboxDao;
  final String attemptPublicId;
  final String pinnedItemPublicId;
  final Duration _debounce;
  final DebounceScheduler _scheduler;

  Timer? _debounceTimer;

  void draftChanged(String text) {
    emit(state.copyWith(draftText: text));
    _debounceTimer?.cancel();
    _debounceTimer = _scheduler(_debounce, () => unawaited(_persist()));
  }

  Future<void> _persist() {
    return _outboxDao.upsertAnswer(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      payload: state.draftText,
    );
  }

  @override
  Future<void> flushPendingEdit() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _persist();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
