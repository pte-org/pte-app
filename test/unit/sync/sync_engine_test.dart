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
