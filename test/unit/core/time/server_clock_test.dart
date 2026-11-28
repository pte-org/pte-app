import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/time/server_clock.dart';

/// FR-02: the exam timer must follow server time, not the device clock.
/// [ServerClock] keeps one anchor (the server time seen at the last
/// `syncWith`, e.g. from the HTTP `Date` header or a `serverTime` field) and
/// then advances it with a MONOTONIC elapsed reading, so neither a wrong
/// device clock nor a device clock changed mid-exam can stretch or shrink the
/// time the student has.
class _FakeTime {
  DateTime wall = DateTime.utc(2026, 11, 28, 10);
  Duration monotonic = Duration.zero;

  DateTime readWall() => wall;
  Duration readMonotonic() => monotonic;
}

const Duration _tenMinutes = Duration(minutes: 10);
const Duration _oneHour = Duration(hours: 1);
const Duration _fiveSeconds = Duration(seconds: 5);

void main() {
  late _FakeTime time;
  late ServerClock clock;

  setUp(() {
    time = _FakeTime();
    clock = ServerClock(
      wallClock: time.readWall,
      monotonicElapsed: time.readMonotonic,
    );
  });

  group('before the first sync', () {
    test('now() follows the device wall clock and the offset is zero', () {
      expect(clock.isSynced, isFalse);
      expect(clock.offset, Duration.zero);
      expect(clock.now(), time.wall);
    });
  });

  group('syncWith', () {
    test('a device clock that is behind the server is corrected', () {
      final serverTime = time.wall.add(_tenMinutes);

      clock.syncWith(serverTime);

      expect(clock.isSynced, isTrue);
      expect(clock.offset, _tenMinutes);
      expect(clock.now(), serverTime);
    });

    test('a device clock that is ahead of the server is corrected', () {
      final serverTime = time.wall.subtract(_tenMinutes);

      clock.syncWith(serverTime);

      expect(clock.offset, -_tenMinutes);
      expect(clock.now(), serverTime);
    });

    test('after the sync, now() advances with the monotonic clock only', () {
      final serverTime = time.wall.add(_tenMinutes);
      clock.syncWith(serverTime);

      time.monotonic += _fiveSeconds;

      expect(clock.now(), serverTime.add(_fiveSeconds));
    });

    test('moving the device clock backwards does not move now() back', () {
      final serverTime = time.wall.add(_tenMinutes);
      clock.syncWith(serverTime);

      time.wall = time.wall.subtract(_oneHour);
      time.monotonic += _fiveSeconds;

      expect(clock.now(), serverTime.add(_fiveSeconds));
    });

    test('moving the device clock forwards does not move now() forward', () {
      final serverTime = time.wall.add(_tenMinutes);
      clock.syncWith(serverTime);

      time.wall = time.wall.add(_oneHour);
      time.monotonic += _fiveSeconds;

      expect(clock.now(), serverTime.add(_fiveSeconds));
    });

    test('a later sync replaces the anchor', () {
      clock.syncWith(time.wall.add(_tenMinutes));
      time.monotonic += _oneHour;

      final secondServerTime = DateTime.utc(2026, 11, 28, 12);
      clock.syncWith(secondServerTime);

      expect(clock.now(), secondServerTime);
    });
  });
}
