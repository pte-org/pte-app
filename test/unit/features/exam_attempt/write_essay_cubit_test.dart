import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/write_essay_cubit.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

/// Mirrors `timer_service_test.dart`'s `_CapturingScheduler` pattern:
/// captures every `(duration, callback)` pair `WriteEssayCubit` schedules
/// via its injectable `DebounceScheduler` so tests can drive the debounce
/// callback manually instead of waiting on real time. Returns a long-lived,
/// never-really-firing `Timer` so `Timer.cancel()` calls made by production
/// code remain harmless no-ops.
class _CapturingScheduler {
  final List<void Function()> callbacks = [];
  final List<Duration> durations = [];
  int cancelCount = 0;

  Timer call(Duration duration, void Function() callback) {
    durations.add(duration);
    callbacks.add(callback);
    return _FakeTimer(this);
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this._scheduler);
  final _CapturingScheduler _scheduler;
  bool _cancelled = false;

  @override
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _scheduler.cancelCount++;
    }
  }

  @override
  bool get isActive => !_cancelled;

  @override
  int get tick => 0;
}

void main() {
  late _MockAnswerOutboxDao outboxDao;

  setUp(() {
    outboxDao = _MockAnswerOutboxDao();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  group('draftChanged — payload-shape assertion (Step 8)', () {
    test('typed text "hello world" writes exactly "hello world" on debounce expiry, no trimming/normalization', () async {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('hello world');
      // Fire the captured debounce callback manually — no real Duration wait.
      scheduler.callbacks.single();
      await pumpEventQueue();

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured, hasLength(1));
      expect(captured.single, 'hello world');

      await cubit.close();
    });

    test('leading/trailing whitespace the student actually typed is preserved verbatim in the payload', () async {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('  hello world  ');
      scheduler.callbacks.single();
      await pumpEventQueue();

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, '  hello world  ');

      await cubit.close();
    });
  });

  group('draftChanged — emits draftText and precomputed wordCount immediately, before the debounce fires', () {
    test('state updates synchronously on every keystroke, independent of the debounce timer', () {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('hello world');

      expect(cubit.state.draftText, 'hello world');
      expect(cubit.state.wordCount, 2);
      // No upsert yet — the debounce callback hasn't been invoked.
      verifyNever(
        () => outboxDao.upsertAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      );

      unawaited(cubit.close());
    });
  });

  group('debounce behavior via fake DebounceScheduler — no real Duration sleeps (Step 9)', () {
    test('rapid simulated draftChanged calls within the debounce window produce zero upsertAnswer calls until the '
        "scheduler's captured callback is manually invoked", () async {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('h');
      cubit.draftChanged('he');
      cubit.draftChanged('hel');
      cubit.draftChanged('hell');
      cubit.draftChanged('hello');

      verifyNever(
        () => outboxDao.upsertAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      );

      // Each keystroke cancels the previous timer and reschedules a new
      // one — 5 keystrokes means 5 scheduler invocations, but only the
      // final (most recent) callback should still matter.
      expect(scheduler.callbacks.length, 5);

      // Firing only the last (live) callback should persist the latest text.
      scheduler.callbacks.last();
      await pumpEventQueue();

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured, hasLength(1));
      expect(captured.single, 'hello');

      await cubit.close();
    });

    test('calling flushPendingEdit mid-debounce produces the upsert call immediately without invoking the '
        'scheduled callback', () async {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('hello world');
      verifyNever(
        () => outboxDao.upsertAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      );

      await cubit.flushPendingEdit();

      final captured = verify(
        () => outboxDao.upsertAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured, hasLength(1));
      expect(captured.single, 'hello world');

      // The pending timer must have been cancelled by the flush, not left
      // to fire independently and double-write — the upsert happened
      // without ever invoking the scheduled callback.
      expect(scheduler.cancelCount, greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('close() cancels the pending debounce timer', () async {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('hello');
      expect(scheduler.cancelCount, 0);

      await cubit.close();

      expect(scheduler.cancelCount, 1);
    });
  });

  group('pinnedItemPublicId threading', () {
    test('every debounced upsertAnswer call carries the pinnedItemPublicId from construction', () async {
      final scheduler = _CapturingScheduler();
      final cubit = WriteEssayCubit(
        outboxDao: outboxDao,
        attemptPublicId: 'attempt-9',
        pinnedItemPublicId: 'item-9',
        scheduler: scheduler.call,
      );

      cubit.draftChanged('draft text');
      scheduler.callbacks.single();
      await pumpEventQueue();

      verify(
        () => outboxDao.upsertAnswer(attemptPublicId: 'attempt-9', pinnedItemPublicId: 'item-9', payload: 'draft text'),
      ).called(1);

      await cubit.close();
    });
  });
}
