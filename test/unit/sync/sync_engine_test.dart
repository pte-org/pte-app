import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/rate_limit_backoff.dart';
import 'package:pte_app/core/sync/sync_engine.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockApiClient extends Mock implements ApiClient {}

class _FakeCanary implements NetworkCanary {
  _FakeCanary(this.available);

  @override
  final Stream<void> available;

  @override
  Future<void> dispose() async {}
}

AnswerOutbox _row({
  String attemptPublicId = 'attempt-1',
  String pinnedItemPublicId = 'item-1',
  String payload = 'payload',
  AnswerSyncStatus status = AnswerSyncStatus.pending,
}) {
  return AnswerOutbox(
    attemptPublicId: attemptPublicId,
    pinnedItemPublicId: pinnedItemPublicId,
    payload: payload,
    status: status.name,
    createdAt: 0,
    updatedAt: 0,
  );
}

Response<void> _okResponse() => Response<void>(requestOptions: RequestOptions(path: '/x'), statusCode: 200);

void main() {
  late _MockAnswerOutboxDao dao;
  late _MockApiClient apiClient;
  late StreamController<void> canaryController;
  late _FakeCanary canary;

  setUpAll(() {
    registerFallbackValue(AnswerSyncStatus.pending);
  });

  setUp(() {
    dao = _MockAnswerOutboxDao();
    apiClient = _MockApiClient();
    canaryController = StreamController<void>.broadcast();
    canary = _FakeCanary(canaryController.stream);
    when(() => dao.checkpointWal()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await canaryController.close();
  });

  test(
    'flushes exactly the pending rows for the started attempt, never a different attemptPublicId '
    'and never terminalRejected/synced rows',
    () async {
      when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
      when(
        () => apiClient.submitAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _okResponse());
      when(() => dao.markSynced(any(), any())).thenAnswer((_) async {});

      final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
      engine.startSync('attempt-1');
      canaryController.add(null);
      await Future<void>.delayed(Duration.zero);

      verify(() => dao.queryPendingByAttempt('attempt-1')).called(1);
      verify(
        () => apiClient.submitAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'p1', payload: 'payload'),
      ).called(1);
      verify(() => dao.markSynced('attempt-1', 'p1')).called(1);
    },
  );

  test('a 409 response results in markTerminalRejected, never a retry loop', () async {
    when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
    when(
      () => apiClient.submitAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(const ConflictException('NOT_CURRENT_TASK'));
    when(() => dao.markTerminalRejected(any(), any(), any())).thenAnswer((_) async {});

    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');
    canaryController.add(null);
    await Future<void>.delayed(Duration.zero);

    verify(() => dao.markTerminalRejected('attempt-1', 'p1', 'NOT_CURRENT_TASK')).called(1);
    verifyNever(() => dao.markSynced(any(), any()));
  });

  test('a ValidationException also results in markTerminalRejected — retrying the same malformed payload forever cannot succeed', () async {
    when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
    when(
      () => apiClient.submitAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(const ValidationException('Request rejected (400)'));
    when(() => dao.markTerminalRejected(any(), any(), any())).thenAnswer((_) async {});

    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');
    canaryController.add(null);
    await Future<void>.delayed(Duration.zero);

    verify(() => dao.markTerminalRejected('attempt-1', 'p1', 'Request rejected (400)')).called(1);
    verifyNever(() => dao.markSynced(any(), any()));
  });

  test(
    'an AuthException leaves the row pending (session-level failure, not a row-specific one — retries indefinitely by design)',
    () async {
      when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
      when(
        () => apiClient.submitAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(const AuthException('Authentication failed (401)'));

      final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
      engine.startSync('attempt-1');
      canaryController.add(null);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => dao.markSynced(any(), any()));
      verifyNever(() => dao.markTerminalRejected(any(), any(), any()));
    },
  );

  test('a NetworkException leaves the row untouched for the next tick (no mark* call)', () async {
    when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
    when(
      () => apiClient.submitAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(const NetworkException('connection refused'));

    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');
    canaryController.add(null);
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => dao.markSynced(any(), any()));
    verifyNever(() => dao.markTerminalRejected(any(), any(), any()));
    verifyNever(() => dao.markPending(any(), any()));
  });

  test('starting for a second, different attemptPublicId while running throws StateError', () {
    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');

    expect(() => engine.startSync('attempt-2'), throwsA(isA<StateError>()));
  });

  test('starting again with the same attemptPublicId while running is a no-op, not an error', () {
    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');

    expect(() => engine.startSync('attempt-1'), returnsNormally);
  });

  test('flushNow triggers an immediate flush pass for the running attempt, independent of any canary/periodic trigger', () async {
    when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
    when(
      () => apiClient.submitAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => _okResponse());
    when(() => dao.markSynced(any(), any())).thenAnswer((_) async {});

    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');
    await engine.flushNow('attempt-1');

    verify(
      () => apiClient.submitAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'p1', payload: 'payload'),
    ).called(1);
  });

  test('flushNow is a no-op if attemptPublicId is not the currently running attempt', () async {
    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
    engine.startSync('attempt-1');

    await engine.flushNow('attempt-2');

    verifyNever(() => dao.queryPendingByAttempt(any()));
  });

  test(
    'a pending row matching setActiveTask is never selected by a canary- or periodic-triggered flush, '
    'but flushOne still flushes it directly',
    () async {
      void Function(Timer)? periodicCallback;
      Timer fakePeriodicTimer(Duration period, void Function(Timer) callback) {
        periodicCallback = callback;
        return Timer(const Duration(days: 999), () {});
      }

      when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'active')]);
      when(() => dao.getAnswer('attempt-1', 'active')).thenAnswer((_) async => _row(pinnedItemPublicId: 'active'));
      when(
        () => apiClient.submitAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _okResponse());
      when(() => dao.markSynced(any(), any())).thenAnswer((_) async {});

      final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary, createPeriodicTimer: fakePeriodicTimer);
      engine.startSync('attempt-1');
      engine.setActiveTask('active');

      canaryController.add(null);
      await Future<void>.delayed(Duration.zero);
      periodicCallback!(Timer(Duration.zero, () {}));
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => apiClient.submitAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      );

      await engine.flushOne('active');

      verify(
        () => apiClient.submitAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'active', payload: 'payload'),
      ).called(1);
    },
  );

  group('Typed-409 dispatch and taskRejectedExternally regression', () {
    test(
      'NotCurrentTaskException marks terminal-rejected AND emits on taskRejectedExternally',
      () async {
        when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
        when(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(const NotCurrentTaskException('NOT_CURRENT_TASK'));
        when(() => dao.markTerminalRejected(any(), any(), any())).thenAnswer((_) async {});

        final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
        var rejectedCount = 0;
        final sub = engine.taskRejectedExternally.listen((_) => rejectedCount++);
        addTearDown(sub.cancel);

        engine.startSync('attempt-1');
        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);

        verify(() => dao.markTerminalRejected('attempt-1', 'p1', 'NOT_CURRENT_TASK')).called(1);
        expect(rejectedCount, 1);
      },
    );

    test(
      'ResponseWindowExpiredException marks terminal-rejected AND emits on taskRejectedExternally',
      () async {
        when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
        when(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(const ResponseWindowExpiredException('RESPONSE_WINDOW_EXPIRED'));
        when(() => dao.markTerminalRejected(any(), any(), any())).thenAnswer((_) async {});

        final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
        var rejectedCount = 0;
        final sub = engine.taskRejectedExternally.listen((_) => rejectedCount++);
        addTearDown(sub.cancel);

        engine.startSync('attempt-1');
        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);

        verify(() => dao.markTerminalRejected('attempt-1', 'p1', 'RESPONSE_WINDOW_EXPIRED')).called(1);
        expect(rejectedCount, 1);
      },
    );

    test(
      'the generic-fallback ConflictException (e.g. ANSWER_ALREADY_SUBMITTED, or an unrecognized future 409 code) '
      'marks terminal-rejected but does NOT emit on taskRejectedExternally',
      () async {
        when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
        when(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(const ConflictException('ANSWER_ALREADY_SUBMITTED'));
        when(() => dao.markTerminalRejected(any(), any(), any())).thenAnswer((_) async {});

        final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary);
        var rejectedCount = 0;
        final sub = engine.taskRejectedExternally.listen((_) => rejectedCount++);
        addTearDown(sub.cancel);

        engine.startSync('attempt-1');
        canaryController.add(null);
        await Future<void>.delayed(Duration.zero);

        verify(() => dao.markTerminalRejected('attempt-1', 'p1', 'ANSWER_ALREADY_SUBMITTED')).called(1);
        expect(rejectedCount, 0);
      },
    );
  });

  group('429 rate-limit backoff via shared RateLimitBackoff (Step 9)', () {
    test(
      'a RateLimitException on one flush pass suppresses the ENTIRE next flush pass (for all pending rows, not '
      'just the one that 429\'d) until the fake-clock backoff window elapses, and a subsequent successful flush '
      'resets the backoff so a later pass is no longer suppressed',
      () async {
        var currentTime = DateTime(2026, 1, 1, 0, 0, 0);
        final backoff = RateLimitBackoff(
          baseInterval: const Duration(seconds: 1),
          maxInterval: const Duration(seconds: 32),
          now: () => currentTime,
        );

        when(() => dao.markSynced(any(), any())).thenAnswer((_) async {});

        // Pass 1: one pending row, submitAnswer throws RateLimitException
        // with no server-supplied Retry-After — falls back to the
        // exponential backoff starting at baseInterval (1s).
        when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
        when(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(const RateLimitException('Rate limited (429)'));

        final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary, backoff: backoff);
        engine.startSync('attempt-1');

        await engine.flushNow('attempt-1');
        verify(() => dao.queryPendingByAttempt('attempt-1')).called(1);
        verify(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
        expect(backoff.isActive, isTrue, reason: 'a 429 must arm the cooldown immediately');
        verifyNever(() => dao.markTerminalRejected(any(), any(), any()));

        // Pass 2: still within the cooldown window (same fake time) — the
        // ENTIRE pass must be skipped, not even a query for pending rows,
        // let alone a second submitAnswer attempt for any row. mocktail's
        // verify() consumes previously-matched invocations (like Mockito),
        // so verifyNever here checks specifically for calls NEW since the
        // pass-1 verify() calls above, since those already consumed pass 1's.
        await engine.flushNow('attempt-1');
        verifyNever(() => dao.queryPendingByAttempt('attempt-1'));
        verifyNever(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        );

        // Advance the fake clock past the 1s cooldown window.
        currentTime = currentTime.add(const Duration(seconds: 2));
        expect(backoff.isActive, isFalse, reason: 'the cooldown window has elapsed per the fake clock');

        // Pass 3: cooldown elapsed — now succeeds and must reset the backoff.
        when(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async => _okResponse());

        await engine.flushNow('attempt-1');
        verify(() => dao.markSynced('attempt-1', 'p1')).called(1);
        expect(backoff.isActive, isFalse, reason: 'a successful flush must reset() the backoff');

        // Pass 4: a fresh 429 immediately after reset must be treated as
        // the first cooldown again (i.e. reset() actually cleared prior
        // exponential growth), proving the "later pass is no longer
        // suppressed" half of the contract holds even after a prior 429.
        when(
          () => apiClient.submitAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(const RateLimitException('Rate limited (429)'));
        await engine.flushNow('attempt-1');
        expect(backoff.isActive, isTrue);
      },
    );

    test('a Retry-After-bearing RateLimitException uses the server-supplied duration verbatim, not the exponential default', () async {
      var currentTime = DateTime(2026, 1, 1, 0, 0, 0);
      final backoff = RateLimitBackoff(now: () => currentTime);

      when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
      when(
        () => apiClient.submitAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(const RateLimitException('Rate limited (429)', retryAfter: Duration(seconds: 10)));

      final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary, backoff: backoff);
      engine.startSync('attempt-1');
      await engine.flushNow('attempt-1');

      currentTime = currentTime.add(const Duration(seconds: 5));
      expect(backoff.isActive, isTrue, reason: 'only 5 of the 10 server-supplied seconds have elapsed');

      currentTime = currentTime.add(const Duration(seconds: 6));
      expect(backoff.isActive, isFalse, reason: 'now past the 10s server-supplied window');
    });
  });

  test('a canary event and a periodic tick firing at effectively the same instant never overlap', () async {
    void Function(Timer)? periodicCallback;
    Timer fakePeriodicTimer(Duration period, void Function(Timer) callback) {
      periodicCallback = callback;
      return Timer(const Duration(days: 999), () {});
    }

    when(() => dao.queryPendingByAttempt('attempt-1')).thenAnswer((_) async => [_row(pinnedItemPublicId: 'p1')]);
    when(
      () => apiClient.submitAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _okResponse();
    });
    when(() => dao.markSynced(any(), any())).thenAnswer((_) async {});

    final engine = SyncEngine(outboxDao: dao, apiClient: apiClient, canary: canary, createPeriodicTimer: fakePeriodicTimer);
    engine.startSync('attempt-1');

    // Fire both triggers back to back, before either's in-flight submitAnswer resolves.
    periodicCallback!(Timer(Duration.zero, () {}));
    canaryController.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(
      () => apiClient.submitAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'p1', payload: 'payload'),
    ).called(1);
  });
}
