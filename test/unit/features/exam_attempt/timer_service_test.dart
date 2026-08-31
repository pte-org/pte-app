import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/exam_attempt/domain/repositories/timer_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_service.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_state_response.dart';

class _MockTimerRepository extends Mock implements TimerRepository {}

/// Mirrors `proactive_refresh_scheduler_test.dart`'s fake-`Timer`-factory
/// pattern: captures every `(duration, callback)` pair a `TimerService`
/// schedules via its injectable `TimerScheduler` so tests can drive poll/tick
/// callbacks manually instead of waiting on real time. Returns a
/// long-lived, never-really-firing `Timer` so `Timer.cancel()` calls made by
/// production code remain harmless no-ops.
///
/// [timers] also exposes the exact `Timer` object returned for each call
/// (plans/phat-speaking-dynamic-prep-timing, Phase 4 — 2nd-pass plan-reviewer
/// finding): a regression test built only on re-invoking a captured
/// `callback` closure bypasses real `Timer.cancel()` semantics entirely, so
/// it can't tell "cancelled" apart from "closure still happens to work" —
/// it would pass even if production code's cancel-before-reconcile step
/// were silently removed. Tests that need to prove a real cancellation
/// happened assert on `timers[i].isActive` instead.
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

TaskView _task({
  required DateTime serverNow,
  DateTime? prepDeadline,
  DateTime? responseDeadline,
  int orderIndex = 1,
  DateTime? examEndTime,
}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: orderIndex,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: 30,
    responseSeconds: 60,
    prepDeadline: prepDeadline ?? DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: responseDeadline ?? DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: serverNow,
    examEndTime: examEndTime,
  );
}

TimerStateResponse _serverState({
  required TimerPhase phase,
  required int currentOrderIndex,
  DateTime? prepDeadline,
  DateTime? responseDeadline,
  required DateTime serverNow,
  DateTime? examEndTime,
}) {
  return TimerStateResponse(
    phase: phase,
    currentOrderIndex: currentOrderIndex,
    prepDeadline: prepDeadline ?? DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: responseDeadline ?? DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: serverNow,
    examEndTime: examEndTime,
  );
}

void main() {
  late _MockTimerRepository repository;

  setUpAll(() {
    registerFallbackValue(
      _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1)),
    );
  });

  setUp(() {
    repository = _MockTimerRepository();
  });

  group('seedFromTask — initial phase derivation (Step 8)', () {
    test('serverNow between prepDeadline and responseDeadline derives phase = response, not prep', () {
      final service = TimerService(timerRepository: repository);
      final task = _task(
        serverNow: DateTime(2026, 1, 1, 0, 0, 45),
        prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
        responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
      );

      service.seedFromTask(task);

      expect(service.currentSnapshot.phase, TimerPhase.response);
      expect(service.currentSnapshot.remaining, greaterThan(Duration.zero));
      expect(service.currentSnapshot.remaining, lessThanOrEqualTo(const Duration(seconds: 45)));
    });

    test('serverNow before prepDeadline derives phase = prep (the inverse case)', () {
      final service = TimerService(timerRepository: repository);
      final task = _task(
        serverNow: DateTime(2026, 1, 1, 0, 0, 10),
        prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
        responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
      );

      service.seedFromTask(task);

      expect(service.currentSnapshot.phase, TimerPhase.prep);
      expect(service.currentSnapshot.remaining, greaterThan(Duration.zero));
      expect(service.currentSnapshot.remaining, lessThanOrEqualTo(const Duration(seconds: 20)));
    });

    test('already past both deadlines at fetch time renders zero/expired immediately, never negative', () {
      final service = TimerService(timerRepository: repository);
      final task = _task(
        serverNow: DateTime(2026, 1, 1, 0, 5, 0),
        prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
        responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
      );

      service.seedFromTask(task);

      expect(service.currentSnapshot.remaining, Duration.zero);
    });

    test('seedFromTask adopts the task orderIndex into the snapshot', () {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10), orderIndex: 3));

      expect(service.currentSnapshot.currentOrderIndex, 3);
    });
  });

  group('reconcileFromServer — server phase wins, no re-derivation (Step 9)', () {
    test('resets the Stopwatch-derived remaining time to the server-computed value', () {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10)));

      final response = _serverState(
        phase: TimerPhase.response,
        currentOrderIndex: 1,
        responseDeadline: DateTime(2026, 1, 1, 0, 1, 0),
        serverNow: DateTime(2026, 1, 1, 0, 0, 40),
      );
      service.reconcileFromServer(response);

      expect(service.currentSnapshot.remaining, lessThanOrEqualTo(const Duration(seconds: 20)));
      expect(service.currentSnapshot.remaining, greaterThan(Duration.zero));
    });

    test(
      'adopts response.phase directly — even when serverNow/deadlines on the same response would derive '
      'a different phase, the explicit phase field wins, not a re-run of the bootstrap derivation',
      () {
        final service = TimerService(timerRepository: repository);
        service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10)));

        // serverNow (0:10) is before prepDeadline (0:30) — a fresh derivation
        // would say "prep" — but the response explicitly states "response".
        final response = _serverState(
          phase: TimerPhase.response,
          currentOrderIndex: 1,
          prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
          responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
          serverNow: DateTime(2026, 1, 1, 0, 0, 10),
        );
        service.reconcileFromServer(response);

        expect(service.currentSnapshot.phase, TimerPhase.response);
      },
    );
  });

  group('taskAdvancedExternally — signaled only on currentOrderIndex change (Step 10)', () {
    test('an unchanged currentOrderIndex across reconciliations does not emit', () async {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10), orderIndex: 1));

      var advancedCount = 0;
      final sub = service.taskAdvancedExternally.listen((_) => advancedCount++);

      service.reconcileFromServer(
        _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1, 0, 0, 15)),
      );
      service.reconcileFromServer(
        _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1, 0, 0, 20)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(advancedCount, 0);
      await sub.cancel();
    });

    test('a changed currentOrderIndex emits exactly once per change', () async {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10), orderIndex: 1));

      var advancedCount = 0;
      final sub = service.taskAdvancedExternally.listen((_) => advancedCount++);

      // 1 -> 1 (no change)
      service.reconcileFromServer(
        _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1, 0, 0, 15)),
      );
      // 1 -> 2 (change #1)
      service.reconcileFromServer(
        _serverState(phase: TimerPhase.prep, currentOrderIndex: 2, serverNow: DateTime(2026, 1, 1, 0, 0, 20)),
      );
      // 2 -> 2 (no change)
      service.reconcileFromServer(
        _serverState(phase: TimerPhase.prep, currentOrderIndex: 2, serverNow: DateTime(2026, 1, 1, 0, 0, 25)),
      );
      // 2 -> 3 (change #2)
      service.reconcileFromServer(
        _serverState(phase: TimerPhase.prep, currentOrderIndex: 3, serverNow: DateTime(2026, 1, 1, 0, 0, 30)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(advancedCount, 2);
      await sub.cancel();
    });
  });

  group('examRemaining — derived from server-provided examEndTime, not a hardcoded constant', () {
    test('seedFromTask with no examEndTime leaves examRemaining at zero', () {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10)));

      expect(service.currentSnapshot.examRemaining, Duration.zero);
    });

    test('seedFromTask computes examRemaining as examEndTime minus serverNow', () {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(
        _task(
          serverNow: DateTime(2026, 1, 1, 0, 0, 10),
          examEndTime: DateTime(2026, 1, 1, 1, 0, 10),
        ),
      );

      expect(service.currentSnapshot.examRemaining, lessThanOrEqualTo(const Duration(hours: 1)));
      expect(service.currentSnapshot.examRemaining, greaterThan(const Duration(minutes: 59, seconds: 59)));
    });

    test('a later reconciliation without examEndTime keeps the previously-known deadline, not resetting to zero', () {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(
        _task(
          serverNow: DateTime(2026, 1, 1, 0, 0, 10),
          examEndTime: DateTime(2026, 1, 1, 1, 0, 10),
        ),
      );

      service.reconcileFromServer(
        _serverState(
          phase: TimerPhase.response,
          currentOrderIndex: 1,
          serverNow: DateTime(2026, 1, 1, 0, 0, 40),
          // examEndTime omitted — mirrors a stale/older backend payload.
        ),
      );

      expect(service.currentSnapshot.examRemaining, lessThanOrEqualTo(const Duration(minutes: 59, seconds: 30)));
      expect(service.currentSnapshot.examRemaining, greaterThan(const Duration(minutes: 59, seconds: 20)));
    });

    test('already past examEndTime renders zero, never negative', () {
      final service = TimerService(timerRepository: repository);
      service.seedFromTask(
        _task(
          serverNow: DateTime(2026, 1, 1, 1, 30, 0),
          examEndTime: DateTime(2026, 1, 1, 1, 0, 10),
        ),
      );

      expect(service.currentSnapshot.examRemaining, Duration.zero);
    });
  });

  group('dispose() — cancels the poll scheduler and closes both streams (Step 11)', () {
    test('no timer continues firing after dispose, verified via the fake scheduler, not a real-time wait', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(timerRepository: repository, scheduler: scheduler.call);
      when(
        () => repository.fetchTimerState(any()),
      ).thenAnswer((_) async => _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1)));

      service.startPolling('attempt-1', interval: const Duration(seconds: 10));
      await pumpEventQueue();

      final scheduledBeforeDispose = scheduler.callbacks.length;
      expect(scheduledBeforeDispose, greaterThan(0));

      service.dispose();

      // Streams are closed: a broadcast controller that's been closed
      // reports no further events and completes immediately.
      expect(await service.ticks.isEmpty, isTrue);
      expect(await service.taskAdvancedExternally.isEmpty, isTrue);

      // Invoking every callback that was captured before dispose must be a
      // safe no-op: no new schedule call is appended (the stale generation
      // check returns before rescheduling), and it must not throw despite
      // the streams now being closed (it never reaches `_ticksController.add`).
      for (final callback in List<void Function()>.from(scheduler.callbacks)) {
        expect(callback, returnsNormally);
      }
      expect(scheduler.callbacks.length, scheduledBeforeDispose);
    });
  });

  group('regression: startPolling called twice without an intervening stop() never leaves two live chains', () {
    test(
      'a stale callback captured by the first startPolling becomes an inert no-op after a second startPolling '
      'supersedes it — no duplicate fetchTimerState calls, no duplicate ticks emissions',
      () async {
        final scheduler = _CapturingScheduler();
        final service = TimerService(timerRepository: repository, scheduler: scheduler.call);
        var fetchCount = 0;
        when(() => repository.fetchTimerState(any())).thenAnswer((_) async {
          fetchCount++;
          return _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1));
        });

        // First task transition.
        service.startPolling('attempt-1', interval: const Duration(seconds: 10));
        await pumpEventQueue();
        expect(fetchCount, 1);

        // Capture the first chain's local-tick callback (scheduled
        // synchronously as the very first captured callback) before it's
        // superseded.
        final staleTickCallback = scheduler.callbacks.first;
        final capturedCountAfterFirstChain = scheduler.callbacks.length;

        var tickEmissions = 0;
        final sub = service.ticks.listen((_) => tickEmissions++);

        // Second task transition — supersedes the first chain without an
        // intervening explicit stop() call from the caller (startPolling
        // calls stop() internally).
        service.startPolling('attempt-1', interval: const Duration(seconds: 10));
        await pumpEventQueue();
        expect(fetchCount, 2); // exactly one more call, for chain #2 only

        final capturedCountAfterSecondChain = scheduler.callbacks.length;
        expect(capturedCountAfterSecondChain, greaterThan(capturedCountAfterFirstChain));

        // Invoking the first (now-stale) chain's tick callback must not
        // reschedule itself nor emit a tick — it recognizes its generation
        // is superseded.
        tickEmissions = 0;
        staleTickCallback();
        await pumpEventQueue();

        expect(tickEmissions, 0);
        expect(scheduler.callbacks.length, capturedCountAfterSecondChain);
        expect(fetchCount, 2); // unchanged — the stale callback triggered no new poll

        // Sanity: the live (second) chain's own tick callback still works,
        // proving only the stale chain — not polling entirely — was made
        // inert.
        final liveTickCallback = scheduler.callbacks[capturedCountAfterFirstChain];
        liveTickCallback();
        await pumpEventQueue();
        expect(tickEmissions, 1);

        await sub.cancel();
      },
    );
  });

  group('one-shot deadline poll — reconciles promptly for short-prep task types (Phase 4)', () {
    test(
      'startPolling schedules a one-shot poll timed to the current countdown remaining; firing it triggers a '
      'fresh server reconciliation without waiting for the periodic interval',
      () async {
        final scheduler = _CapturingScheduler();
        final service = TimerService(timerRepository: repository, scheduler: scheduler.call);
        var fetchCount = 0;
        when(() => repository.fetchTimerState(any())).thenAnswer((_) async {
          fetchCount++;
          return _serverState(
            phase: TimerPhase.prep,
            currentOrderIndex: 1,
            prepDeadline: DateTime(2026, 1, 1, 0, 0, 10),
            serverNow: DateTime(2026, 1, 1, 0, 0, 5),
          );
        });

        // A short 5s prep window — the scenario this phase exists for.
        service.seedFromTask(
          _task(serverNow: DateTime(2026, 1, 1), prepDeadline: DateTime(2026, 1, 1, 0, 0, 5)),
        );
        service.startPolling('attempt-1', interval: const Duration(seconds: 10));

        // Scheduled synchronously within startPolling, before the initial
        // poll's own async reconciliation runs: [0] tick (1s), [1] the
        // one-shot, targeted at the ~5s remaining — well under the 10s
        // periodic interval, proving it's a distinct, earlier-firing timer.
        expect(scheduler.durations[1], lessThanOrEqualTo(const Duration(seconds: 5)));
        expect(scheduler.durations[1], greaterThan(const Duration(seconds: 3)));

        // startPolling's own initial immediate poll already ran
        // synchronously up to its first await — one fetch so far, no new
        // one from the one-shot mechanism itself yet.
        expect(fetchCount, 1);

        final oneShotCallback = scheduler.callbacks[1];
        oneShotCallback();
        await pumpEventQueue();

        // Firing the one-shot triggered a second, independent server
        // reconciliation — not merely a local tick — without any real time
        // passing and without the 10s periodic interval ever firing.
        expect(fetchCount, 2);
      },
    );

    test(
      'firing the one-shot poll leaves exactly one active periodic chain — the previously-active periodic Timer '
      'is genuinely cancelled, not merely superseded by a new schedule call',
      () async {
        final scheduler = _CapturingScheduler();
        final service = TimerService(timerRepository: repository, scheduler: scheduler.call);
        when(() => repository.fetchTimerState(any())).thenAnswer(
          (_) async => _serverState(
            phase: TimerPhase.prep,
            currentOrderIndex: 1,
            prepDeadline: DateTime(2026, 1, 1, 0, 0, 10),
            serverNow: DateTime(2026, 1, 1, 0, 0, 5),
          ),
        );

        service.seedFromTask(
          _task(serverNow: DateTime(2026, 1, 1), prepDeadline: DateTime(2026, 1, 1, 0, 0, 5)),
        );
        service.startPolling('attempt-1', interval: const Duration(seconds: 10));
        await pumpEventQueue();

        // After the initial poll's own reconciliation, exactly one
        // periodic Timer is active — the last one scheduled (_poll's tail).
        final periodicTimerBeforeOneShot = scheduler.timers.last;
        expect(periodicTimerBeforeOneShot.isActive, isTrue);

        final oneShotCallback = scheduler.callbacks[1];
        oneShotCallback();
        await pumpEventQueue();

        // The one-shot's cancel-before-reconcile step must have called
        // real Timer.cancel() on the previously-active periodic timer —
        // asserting on the closure re-firing safely would not catch a
        // missing cancellation (2nd-pass plan-reviewer finding).
        expect(periodicTimerBeforeOneShot.isActive, isFalse);

        // Exactly one, brand-new periodic timer is active afterward.
        final periodicTimerAfterOneShot = scheduler.timers.last;
        expect(periodicTimerAfterOneShot.isActive, isTrue);
        expect(identical(periodicTimerAfterOneShot, periodicTimerBeforeOneShot), isFalse);
      },
    );

    test(
      'a race where the one-shot fires and re-enters _poll before the original startPolling call\'s own fetch has '
      'resolved still leaves exactly one active periodic chain (code-review finding: _poll\'s own tail-end '
      'scheduling was not symmetric with _scheduleOneShotPoll\'s cancel-before-overwrite)',
      () async {
        final scheduler = _CapturingScheduler();
        final service = TimerService(timerRepository: repository, scheduler: scheduler.call);

        // The very first fetchTimerState call (startPolling's own initial
        // _poll) stays deliberately unresolved until explicitly completed
        // below — simulating a slow/cold network round-trip racing the
        // one-shot's short window. Every later call resolves immediately.
        final firstFetchCompleter = Completer<TimerStateResponse>();
        var fetchCallCount = 0;
        when(() => repository.fetchTimerState(any())).thenAnswer((_) {
          fetchCallCount++;
          if (fetchCallCount == 1) return firstFetchCompleter.future;
          return Future<TimerStateResponse>.value(
            _serverState(
              phase: TimerPhase.prep,
              currentOrderIndex: 1,
              prepDeadline: DateTime(2026, 1, 1, 0, 0, 10),
              serverNow: DateTime(2026, 1, 1, 0, 0, 5),
            ),
          );
        });

        service.seedFromTask(
          _task(serverNow: DateTime(2026, 1, 1), prepDeadline: DateTime(2026, 1, 1, 0, 0, 5)),
        );
        service.startPolling('attempt-1', interval: const Duration(seconds: 10));
        // Deliberately no pumpEventQueue here — the original _poll call's
        // fetch is still pending, so _pollTimer is still null at this exact
        // moment: the race window this test targets.

        final oneShotCallback = scheduler.callbacks[1];
        oneShotCallback();
        await pumpEventQueue();

        // The one-shot-triggered _poll call (2nd+ fetch, resolves
        // immediately) reconciled and scheduled its own periodic timer,
        // while the original call is still stuck awaiting its fetch.
        final periodicTimerFromOneShot = scheduler.timers.last;
        expect(periodicTimerFromOneShot.isActive, isTrue);

        // Now let the original (slow) fetch resolve too.
        firstFetchCompleter.complete(
          _serverState(
            phase: TimerPhase.prep,
            currentOrderIndex: 1,
            prepDeadline: DateTime(2026, 1, 1, 0, 0, 10),
            serverNow: DateTime(2026, 1, 1, 0, 0, 5),
          ),
        );
        await pumpEventQueue();

        // The original call's own tail-end scheduling must have cancelled
        // the one-shot-triggered periodic timer before installing its own
        // — never two independently active periodic chains, regardless of
        // which of the two racing _poll calls finishes last.
        expect(periodicTimerFromOneShot.isActive, isFalse);
        final finalPeriodicTimer = scheduler.timers.last;
        expect(finalPeriodicTimer.isActive, isTrue);
        expect(identical(finalPeriodicTimer, periodicTimerFromOneShot), isFalse);
      },
    );

    test(
      'a fresh reconciliation replaces the previously-scheduled one-shot with one re-targeted at the new deadline',
      () async {
        final scheduler = _CapturingScheduler();
        final service = TimerService(timerRepository: repository, scheduler: scheduler.call);
        when(() => repository.fetchTimerState(any())).thenAnswer(
          (_) async => _serverState(
            phase: TimerPhase.prep,
            currentOrderIndex: 1,
            prepDeadline: DateTime(2026, 1, 1, 0, 0, 10),
            serverNow: DateTime(2026, 1, 1, 0, 0, 5),
          ),
        );

        service.seedFromTask(
          _task(serverNow: DateTime(2026, 1, 1), prepDeadline: DateTime(2026, 1, 1, 0, 0, 5)),
        );
        service.startPolling('attempt-1', interval: const Duration(seconds: 10));
        await pumpEventQueue();

        // [1] the one-shot scheduled synchronously within startPolling is
        // superseded by [2], re-armed once the initial poll's own
        // reconciliation re-seeds the countdown — proving the re-arm
        // (Step 4) runs on every reconciliation, not only when the
        // one-shot itself fires.
        final originalOneShotTimer = scheduler.timers[1];
        expect(originalOneShotTimer.isActive, isFalse);

        final reArmedOneShotTimer = scheduler.timers[2];
        expect(reArmedOneShotTimer.isActive, isTrue);
        expect(scheduler.durations[2], lessThanOrEqualTo(const Duration(seconds: 5)));
      },
    );

    test('stop() leaves no orphaned one-shot callback capable of firing', () async {
      final scheduler = _CapturingScheduler();
      final service = TimerService(timerRepository: repository, scheduler: scheduler.call);
      var fetchCount = 0;
      when(() => repository.fetchTimerState(any())).thenAnswer((_) async {
        fetchCount++;
        return _serverState(
          phase: TimerPhase.prep,
          currentOrderIndex: 1,
          prepDeadline: DateTime(2026, 1, 1, 0, 0, 10),
          serverNow: DateTime(2026, 1, 1, 0, 0, 5),
        );
      });

      service.seedFromTask(
        _task(serverNow: DateTime(2026, 1, 1), prepDeadline: DateTime(2026, 1, 1, 0, 0, 5)),
      );
      service.startPolling('attempt-1', interval: const Duration(seconds: 10));
      await pumpEventQueue();

      final staleOneShotCallback = scheduler.callbacks[1];
      final fetchCountBeforeStop = fetchCount;
      final callbackCountBeforeStop = scheduler.callbacks.length;

      service.stop();
      staleOneShotCallback();
      await pumpEventQueue();

      // The stale generation guard makes this a safe no-op: no new poll,
      // no new schedule call.
      expect(fetchCount, fetchCountBeforeStop);
      expect(scheduler.callbacks.length, callbackCountBeforeStop);
    });

    test(
      'reconcileFromServer called directly (no startPolling active) never schedules a one-shot poll — the '
      'existing seedFromTask/reconcileFromServer-only tests above must stay free of stray real Timers',
      () {
        final scheduler = _CapturingScheduler();
        final service = TimerService(timerRepository: repository, scheduler: scheduler.call);

        service.seedFromTask(_task(serverNow: DateTime(2026, 1, 1, 0, 0, 10)));
        service.reconcileFromServer(
          _serverState(phase: TimerPhase.prep, currentOrderIndex: 1, serverNow: DateTime(2026, 1, 1, 0, 0, 15)),
        );

        expect(scheduler.callbacks, isEmpty);
      },
    );
  });
}
