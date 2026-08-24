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
class _CapturingScheduler {
  final List<void Function()> callbacks = [];
  final List<Duration> durations = [];

  Timer call(Duration duration, void Function() callback) {
    durations.add(duration);
    callbacks.add(callback);
    return Timer(const Duration(days: 999), () {});
  }
}

TaskView _task({
  required DateTime serverNow,
  DateTime? prepDeadline,
  DateTime? responseDeadline,
  int orderIndex = 1,
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
  );
}

TimerStateResponse _serverState({
  required TimerPhase phase,
  required int currentOrderIndex,
  DateTime? prepDeadline,
  DateTime? responseDeadline,
  required DateTime serverNow,
}) {
  return TimerStateResponse(
    phase: phase,
    currentOrderIndex: currentOrderIndex,
    prepDeadline: prepDeadline ?? DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: responseDeadline ?? DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: serverNow,
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
}
