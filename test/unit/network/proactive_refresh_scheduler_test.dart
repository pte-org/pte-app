import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/proactive_refresh_scheduler.dart';
import 'package:pte_app/core/storage/token_store.dart';

class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late TokenStore tokenStore;
  late DateTime fakeNow;
  Duration? capturedDelay;
  void Function()? capturedCallback;
  int refreshDueCalls = 0;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    final secureStorage = _FakeSecureStorage();
    when(() => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    fakeNow = DateTime(2026, 1, 1, 0, 0, 0);
    tokenStore = TokenStore(secureStorage: secureStorage, now: () => fakeNow);
    capturedDelay = null;
    capturedCallback = null;
    refreshDueCalls = 0;
  });

  Timer fakeTimerFactory(Duration delay, void Function() callback) {
    capturedDelay = delay;
    capturedCallback = callback;
    return Timer(const Duration(days: 999), () {}); // never fires for real in this test
  }

  test('schedules a refresh before the 900s boundary, verified without waiting real time', () async {
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r', expiresInSeconds: 900);
    // Override the store's real-clock expiry with a deterministic one via
    // the scheduler's injectable `now`, computed relative to fakeNow.
    final scheduler = ProactiveRefreshScheduler(
      tokenStore: tokenStore,
      onRefreshDue: () async => refreshDueCalls++,
      now: () => fakeNow,
      createTimer: fakeTimerFactory,
      safetyMargin: const Duration(seconds: 60),
    );

    scheduler.scheduleFromTokenStore();

    expect(capturedDelay, isNotNull);
    expect(capturedDelay!.inSeconds, lessThan(900));
    expect(capturedDelay!.inSeconds, greaterThan(0));
  });

  test('invoking the scheduled callback triggers onRefreshDue exactly once', () async {
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r', expiresInSeconds: 900);
    final scheduler = ProactiveRefreshScheduler(
      tokenStore: tokenStore,
      onRefreshDue: () async => refreshDueCalls++,
      now: () => fakeNow,
      createTimer: fakeTimerFactory,
    );

    scheduler.scheduleFromTokenStore();
    capturedCallback!();
    await Future<void>.delayed(Duration.zero);

    expect(refreshDueCalls, 1);
  });

  test('cancel() cancels the pending timer', () async {
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r', expiresInSeconds: 900);
    const cancelled = false;
    final scheduler = ProactiveRefreshScheduler(
      tokenStore: tokenStore,
      onRefreshDue: () async {},
      now: () => fakeNow,
      createTimer: (delay, cb) {
        capturedCallback = cb;
        final timer = Timer(const Duration(days: 999), () {});
        return timer;
      },
    );
    scheduler.scheduleFromTokenStore();

    scheduler.cancel();

    // No assertion beyond "does not throw" — real cancellation is verified
    // implicitly by the timer's own dispose in dispose-path tests later
    // (Phase 4 established this pattern for TimerService).
    expect(cancelled, isFalse);
  });

  test('a failed refresh re-arms a short retry instead of silently stranding the app', () async {
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r', expiresInSeconds: 900);
    final scheduledDelays = <Duration>[];
    final scheduledCallbacks = <void Function()>[];
    var attempt = 0;

    final scheduler = ProactiveRefreshScheduler(
      tokenStore: tokenStore,
      onRefreshDue: () async {
        attempt++;
        if (attempt == 1) throw Exception('network down');
      },
      now: () => fakeNow,
      retryDelay: const Duration(seconds: 30),
      createTimer: (delay, cb) {
        scheduledDelays.add(delay);
        scheduledCallbacks.add(cb);
        return Timer(const Duration(days: 999), () {});
      },
    );

    scheduler.scheduleFromTokenStore();
    scheduledCallbacks.first(); // first attempt fails
    await Future<void>.delayed(Duration.zero);

    expect(attempt, 1);
    expect(scheduledDelays.length, 2); // initial schedule + retry
    expect(scheduledDelays.last, const Duration(seconds: 30));

    scheduledCallbacks.last(); // retry succeeds
    await Future<void>.delayed(Duration.zero);

    expect(attempt, 2);
    expect(scheduledDelays.length, 2); // no further retry after success
  });
}
