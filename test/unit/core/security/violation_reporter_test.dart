import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/security/violation_reporter.dart';
import 'package:pte_app/core/security/violation_retry_coordinator.dart';
import 'package:pte_app/core/storage/app_database.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockViolationReporter extends Mock implements ViolationReporter {}

class _FakeCanary implements NetworkCanary {
  _FakeCanary(this.available);

  @override
  final Stream<void> available;

  @override
  Future<void> dispose() async {}
}

ViolationEvent _event({String id = 'event-1', String? detail}) {
  return ViolationEvent(
    clientEventId: id,
    attemptPublicId: 'attempt-1',
    type: ViolationType.fullscreenExit,
    severity: ViolationSeverity.warning,
    timestamp: DateTime.utc(2026, 9, 28, 4, 5, 6),
    metadata: detail,
  );
}

Response<void> _okResponse() => Response<void>(
  requestOptions: RequestOptions(path: '/security-violations'),
  statusCode: 200,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late _MockApiClient apiClient;
  late ViolationReporter reporter;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    apiClient = _MockApiClient();
    reporter = ViolationReporter(
      apiClient: apiClient,
      localDao: db.localViolationDao,
      logger: Logger(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('serializes the exact authenticated attempt payload', () {
    final event = _event(detail: 'x' * 3000);
    final json = event.toJson();

    expect(
      json.keys,
      containsAll(<String>[
        'clientEventId',
        'violationType',
        'clientOccurredAt',
        'detail',
      ]),
    );
    expect(json, isNot(contains('attemptPublicId')));
    expect(json, isNot(contains('severity')));
    expect(json['clientEventId'], 'event-1');
    expect(json['violationType'], 'LOCKDOWN_FULLSCREEN_EXIT');
    expect((json['detail'] as String).length, 2048);
  });

  test(
    'persists before sending and marks the same row sent on success',
    () async {
      when(
        () => apiClient.post<void>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _okResponse());

      await reporter.reportViolation(_event());

      final row = (await db.localViolationDao.getAllForAttempt(
        'attempt-1',
      )).single;
      expect(row.clientEventId, 'event-1');
      expect(row.sent, isTrue);
      expect(row.terminal, isFalse);
      final call = verify(
        () =>
            apiClient.post<void>(captureAny(), data: captureAny(named: 'data')),
      ).captured;
      expect(call[0], '/api/v1/attempts/attempt-1/security-violations');
      expect((call[1] as Map<String, dynamic>)['clientEventId'], 'event-1');
    },
  );

  test(
    'keeps a network failure pending and retries with the same client id',
    () async {
      var calls = 0;
      when(
        () => apiClient.post<void>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw const NetworkException('offline');
        return _okResponse();
      });
      reporter.debugSetRetryCooldown(Duration.zero);

      await reporter.reportViolation(_event());
      expect((await db.localViolationDao.getUnsent()), hasLength(1));

      await reporter.retryUnsent();

      expect(await db.localViolationDao.getUnsent(), isEmpty);
      expect(calls, 2);
      final payloads = verify(
        () => apiClient.post<void>(any(), data: captureAny(named: 'data')),
      ).captured.map((entry) => entry as Map<String, dynamic>);
      expect(payloads.map((payload) => payload['clientEventId']), [
        'event-1',
        'event-1',
      ]);
    },
  );

  test(
    'terminal policy rejection is retained but removed from retry set',
    () async {
      when(
        () => apiClient.post<void>(any(), data: any(named: 'data')),
      ).thenThrow(const ValidationException('SECURITY_AUDIT_DISABLED'));

      await reporter.reportViolation(_event());

      expect(await db.localViolationDao.getUnsent(), isEmpty);
      final row = (await db.localViolationDao.getAllForAttempt(
        'attempt-1',
      )).single;
      expect(row.sent, isFalse);
      expect(row.terminal, isTrue);
      expect(row.terminalReason, 'SECURITY_AUDIT_DISABLED');
    },
  );

  test('retry override is single-flight', () async {
    final firstSweep = Completer<void>();
    var calls = 0;
    reporter.debugSetRetryOverride(() async {
      calls++;
      await firstSweep.future;
    });

    final first = reporter.retryUnsent();
    final second = reporter.retryUnsent();
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    firstSweep.complete();
    await Future.wait([first, second]);
  });

  test(
    'coordinator reacts to reconnect and prevents concurrent sweeps',
    () async {
      final canaryController = StreamController<void>.broadcast();
      final canary = _FakeCanary(canaryController.stream);
      final mockReporter = _MockViolationReporter();
      final sweep = Completer<void>();
      var calls = 0;
      when(() => mockReporter.retryUnsent()).thenAnswer((_) async {
        calls++;
        await sweep.future;
      });

      Timer? timer;
      late void Function(Timer) periodicTick;
      Timer factory(Duration _, void Function(Timer) callback) {
        periodicTick = callback;
        timer = Timer(const Duration(hours: 1), () {});
        return timer!;
      }

      final coordinator = ViolationRetryCoordinator(
        reporter: mockReporter,
        canary: canary,
        createPeriodicTimer: factory,
        logger: Logger(),
      );

      coordinator.start();
      expect(coordinator.isStarted, isTrue);
      canaryController.add(null);
      periodicTick(timer!);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      sweep.complete();
      await Future<void>.delayed(Duration.zero);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.detached);
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.isStarted, isFalse);
      await coordinator.dispose();
      await canaryController.close();
      verify(() => mockReporter.retryUnsent()).called(1);
    },
  );
}
