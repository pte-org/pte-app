import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_service.dart';

/// Mirrors `proactive_refresh_scheduler_test.dart`'s fake-`Timer`-factory
/// pattern: captures every `(duration, callback)` pair `TimerService`
/// schedules via its injectable `TimerScheduler` so tests can drive tick/
/// phase-transition callbacks manually instead of waiting on real time.
/// Returns a long-lived, never-really-firing `Timer` so `Timer.cancel()`
/// calls made by production code remain harmless no-ops. [timers] exposes
/// the exact `Timer` object per call so a test can assert on real
/// `Timer.isActive` transitions, not just closure re-invocation.
class _CapturingScheduler {
  final List<void Function()> callbacks = [];
  final List<Duration> durations = [];
  final List<Timer> timers = [];

  Timer call(Duration duration, void Function() callback) {
    durations.add(duration);
    callbacks.add(callback);
    final timer = Timer(const Duration(days: 999), () {});
    timers.add(timer);
    return timer;
  }
}

TaskView _task({int orderIndex = 1, int prepSeconds = 30, int responseSeconds = 60, DateTime? examEndTime}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: orderIndex,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: prepSeconds,
    responseSeconds: responseSeconds,
    examEndTime: examEndTime,
  );
}

void main() {
  group('seedFromTask — local wall-clock deadlines computed from prepSeconds/responseSeconds (client-side-exam-timer Phase 3)', () {
    test('a task with prepSeconds > 0 starts in prep phase, remaining derived from prepSeconds', () {
      final service = TimerService();
      service.seedFromTask(_task(prepSeconds: 30, responseSeconds: 60));

      expect(service.currentSnapshot.phase, TimerPhase.prep);
      expect(service.currentSnapshot.remaining, lessThanOrEqualTo(const Duration(seconds: 30)));
      expect(service.currentSnapshot.remaining, greaterThan(const Duration(seconds: 28)));
    });

    test('a zero-prep task starts directly in response phase, matching the server\'s equivalent collapse', () {
      final service = TimerService();
      service.seedFromTask(_task(prepSeconds: 0, responseSeconds: 600));

      expect(service.currentSnapshot.phase, TimerPhase.response);
      expect(service.currentSnapshot.remaining, lessThanOrEqualTo(const Duration(seconds: 600)));
      expect(service.currentSnapshot.remaining, greaterThan(const Duration(seconds: 598)));
    });

    test('seedFromTask adopts the task orderIndex into the snapshot', () {
      final service = TimerService();
      service.seedFromTask(_task(orderIndex: 3));

      expect(service.currentSnapshot.currentOrderIndex, 3);
    });

    test('remaining never goes negative once the deadline has passed (checked via the phase-transition path, not a real wait)', () {
      final service = TimerService();
      service.seedFromTask(_task(prepSeconds: 0, responseSeconds: 0));

      expect(service.currentSnapshot.remaining, Duration.zero);
    });
  });

  group('examRemaining — from TaskView.examEndTime, carried forward across seeds (unaffected by this refactor)', () {
    test('no examEndTime leaves examRemaining at zero', () {
      final service = TimerService();
      service.seedFromTask(_task());

      expect(service.currentSnapshot.examRemaining, Duration.zero);
    });

    test('computes examRemaining as examEndTime minus now', () {
      final service = TimerService();
      service.seedFromTask(_task(examEndTime: DateTime.now().add(const Duration(hours: 1))));

      expect(service.currentSnapshot.examRemaining, lessThanOrEqualTo(const Duration(hours: 1)));
      expect(service.currentSnapshot.examRemaining, greaterThan(const Duration(minutes: 59, seconds: 58)));
    });

    test('a later seed with no examEndTime keeps the previously-known deadline, not resetting to zero', () {
      final service = TimerService();
      service.seedFromTask(_task(examEndTime: DateTime.now().add(const Duration(hours: 1))));

      service.seedFromTask(_task(orderIndex: 2)); // next task's response omits examEndTime

      expect(service.currentSnapshot.examRemaining, greaterThan(const Duration(minutes: 59, seconds: 55)));
    });

    test('already past examEndTime renders zero, never negative', () {
      final service = TimerService();
      service.seedFromTask(_task(examEndTime: DateTime.now().subtract(const Duration(minutes: 1))));

      expect(service.currentSnapshot.examRemaining, Duration.zero);
    });
  });

  group('startPolling — arms the local tick + phase-transition timer chain, no network call at all', () {
    test('schedules exactly a tick timer and a phase-transition timer, synchronously', () {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 30, responseSeconds: 60));

      service.startPolling('attempt-1');

      expect(scheduler.durations.length, 2);
      expect(scheduler.durations[0], const Duration(seconds: 1));
      expect(scheduler.durations[1], lessThanOrEqualTo(const Duration(seconds: 30)));
      expect(scheduler.durations[1], greaterThan(const Duration(seconds: 28)));
    });

    test('a zero-prep task schedules no phase-transition timer — nothing left to transition to', () {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 0, responseSeconds: 60));

      service.startPolling('attempt-1');

      expect(scheduler.durations.length, 1);
    });

    test('the tick callback re-emits currentSnapshot and reschedules itself for the next second', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task());
      service.startPolling('attempt-1');
      var tickCount = 0;
      final sub = service.ticks.listen((_) => tickCount++);

      scheduler.callbacks[0]();
      await pumpEventQueue();

      expect(tickCount, 1);
      expect(scheduler.durations.length, 3); // [0] tick, [1] phase-transition, [2] rescheduled tick
      await sub.cancel();
    });

    test('the phase-transition callback flips prep->response locally, with zero network calls, and emits a tick', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 5, responseSeconds: 60));
      service.startPolling('attempt-1');
      expect(service.currentSnapshot.phase, TimerPhase.prep);
      var lastSnapshotPhase = TimerPhase.prep;
      final sub = service.ticks.listen((snapshot) => lastSnapshotPhase = snapshot.phase);

      scheduler.callbacks[1](); // the phase-transition one-shot
      await pumpEventQueue();

      expect(service.currentSnapshot.phase, TimerPhase.response);
      expect(lastSnapshotPhase, TimerPhase.response);
      await sub.cancel();
    });

    test('calling startPolling again supersedes the prior chain — the stale tick becomes an inert no-op', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 30));
      service.startPolling('attempt-1');
      final staleTick = scheduler.callbacks[0];
      final capturedAfterFirstChain = scheduler.callbacks.length;

      service.startPolling('attempt-1'); // no intervening explicit stop() from the caller
      var tickCount = 0;
      final sub = service.ticks.listen((_) => tickCount++);
      staleTick();
      await pumpEventQueue();

      expect(tickCount, 0);
      expect(scheduler.callbacks.length, capturedAfterFirstChain + 2);
      await sub.cancel();
    });

    test('calling startPolling again genuinely cancels the prior chain\'s real Timer objects, not just supersedes the closure', () {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 30));
      service.startPolling('attempt-1');
      final firstTick = scheduler.timers[0];
      final firstPhaseTransition = scheduler.timers[1];

      service.startPolling('attempt-1');

      expect(firstTick.isActive, isFalse);
      expect(firstPhaseTransition.isActive, isFalse);
      expect(scheduler.timers[2].isActive, isTrue);
      expect(scheduler.timers[3].isActive, isTrue);
    });
  });

  group('AppResumed-equivalent — re-arming after a background gap stays correct with no reconciliation step', () {
    test(
      're-calling startPolling after real time has passed still reports the correct remaining time, computed fresh '
      'from the fixed wall-clock deadline seedFromTask established — no Stopwatch to go stale, nothing to correct',
      () async {
        final service = TimerService();
        service.seedFromTask(_task(prepSeconds: 5, responseSeconds: 60));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        service.startPolling('attempt-1'); // mirrors ExamAttemptBloc._onAppResumed

        expect(service.currentSnapshot.phase, TimerPhase.prep);
        expect(service.currentSnapshot.remaining, lessThanOrEqualTo(const Duration(seconds: 5)));
        expect(service.currentSnapshot.remaining, greaterThan(const Duration(seconds: 4)));
      },
    );

    test('startPolling alone (no preceding seedFromTask) is a safe no-op-ish re-arm against whatever deadlines already exist', () {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 30));

      expect(() => service.startPolling('attempt-1'), returnsNormally);
      expect(scheduler.durations.length, 2);
    });
  });

  group(
    'taskAdvancedExternally — never emits (client-side-exam-timer Phase 3: proctor-initiated external advance '
    'detection had no replacement once server reconciliation was removed — accepted capability loss)',
    () {
      test('the stream is safely listenable but never fires', () async {
        final scheduler = _CapturingScheduler();
        final service = TimerService(scheduler: scheduler.call);
        service.seedFromTask(_task(prepSeconds: 1));
        service.startPolling('attempt-1');
        var fired = false;
        final sub = service.taskAdvancedExternally.listen((_) => fired = true);

        scheduler.callbacks[0](); // tick
        scheduler.callbacks[1](); // phase-transition
        await pumpEventQueue();

        expect(fired, isFalse);
        await sub.cancel();
      });
    },
  );

  group('stop()/dispose()', () {
    test('stop() cancels both timers; a stale tick callback afterward reschedules nothing', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task(prepSeconds: 30));
      service.startPolling('attempt-1');
      final staleTick = scheduler.callbacks[0];
      final countBeforeStop = scheduler.callbacks.length;

      service.stop();
      staleTick();
      await pumpEventQueue();

      expect(scheduler.callbacks.length, countBeforeStop);
    });

    test('dispose() stops timers and closes both streams', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(scheduler: scheduler.call);
      service.seedFromTask(_task());
      service.startPolling('attempt-1');

      service.dispose();

      expect(await service.ticks.isEmpty, isTrue);
      expect(await service.taskAdvancedExternally.isEmpty, isTrue);
    });
  });
}
