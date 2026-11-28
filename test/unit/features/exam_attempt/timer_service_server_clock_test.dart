import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/time/server_clock.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_service.dart';

/// FR-02: [TimerService] reads every "now" from an injected [ServerClock]
/// (`TimerService(serverClock: ...)`), never from `DateTime.now()`. The whole
/// attempt deadline (`TaskView.examEndTime`) is a server timestamp, so the
/// time left must be `examEndTime - serverNow`, and a device clock that is
/// wrong, or changed during the exam, must not extend (or cut) that time.
class _FakeTime {
  DateTime wall = DateTime.utc(2026, 11, 28, 10);
  Duration monotonic = Duration.zero;
}

class _CapturingScheduler {
  final List<Duration> durations = [];

  Timer call(Duration duration, void Function() callback) {
    durations.add(duration);
    return Timer(const Duration(days: 999), () {});
  }
}

const Duration _examLength = Duration(minutes: 30);
const Duration _tenMinutes = Duration(minutes: 10);
const Duration _oneHour = Duration(hours: 1);
const Duration _twoHours = Duration(hours: 2);
const Duration _fiveSeconds = Duration(seconds: 5);
const Duration _prepLength = Duration(seconds: 30);

TaskView _task({
  required DateTime examEndTime,
  int prepSeconds = 30,
  int responseSeconds = 60,
}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
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
  late _FakeTime time;
  late ServerClock serverClock;
  late _CapturingScheduler scheduler;
  late TimerService service;
  late DateTime serverNow;
  late DateTime examEnd;

  setUp(() {
    time = _FakeTime();
    serverClock = ServerClock(
      wallClock: () => time.wall,
      monotonicElapsed: () => time.monotonic,
    );
    scheduler = _CapturingScheduler();
    service = TimerService(scheduler: scheduler.call, serverClock: serverClock);
    serverNow = time.wall;
    examEnd = serverNow.add(_examLength);
  });

  tearDown(() => service.dispose());

  group('server offset', () {
    test('a device clock 10 minutes behind the server does not add 10 minutes', () {
      serverNow = time.wall.add(_tenMinutes);
      examEnd = serverNow.add(_examLength);
      serverClock.syncWith(serverNow);

      service.seedFromTask(_task(examEndTime: examEnd));

      expect(service.currentSnapshot.examRemaining, _examLength);
    });

    test('a device clock 10 minutes ahead of the server does not remove 10 minutes', () {
      serverNow = time.wall.subtract(_tenMinutes);
      examEnd = serverNow.add(_examLength);
      serverClock.syncWith(serverNow);

      service.seedFromTask(_task(examEndTime: examEnd));

      expect(service.currentSnapshot.examRemaining, _examLength);
    });

    test('before any sync the timer behaves as before (offset zero)', () {
      service.seedFromTask(_task(examEndTime: examEnd));

      expect(service.currentSnapshot.examRemaining, _examLength);
    });
  });

  group('device clock changes during the exam', () {
    setUp(() {
      serverClock.syncWith(serverNow);
      service.seedFromTask(_task(examEndTime: examEnd));
    });

    test('moving the device clock back an hour does not extend the exam', () {
      time.wall = time.wall.subtract(_oneHour);
      time.monotonic += _fiveSeconds;

      expect(
        service.currentSnapshot.examRemaining,
        _examLength - _fiveSeconds,
      );
    });

    test('moving the device clock forward two hours does not end the exam early', () {
      time.wall = time.wall.add(_twoHours);
      time.monotonic += _fiveSeconds;

      expect(
        service.currentSnapshot.examRemaining,
        _examLength - _fiveSeconds,
      );
    });

    test('the prep countdown follows the monotonic clock too', () {
      time.wall = time.wall.subtract(_oneHour);
      time.monotonic += _fiveSeconds;

      final snapshot = service.currentSnapshot;
      expect(snapshot.phase, TimerPhase.prep);
      expect(snapshot.remaining, _prepLength - _fiveSeconds);
    });

    test('the prep to response transition is scheduled from monotonic time', () {
      time.wall = time.wall.subtract(_oneHour);
      time.monotonic += _fiveSeconds;

      service.startPolling('attempt-1');

      expect(scheduler.durations, contains(_prepLength - _fiveSeconds));
    });

    test('time left never goes below zero once the deadline has passed', () {
      time.monotonic += _examLength + _fiveSeconds;

      expect(service.currentSnapshot.examRemaining, Duration.zero);
    });
  });
}
