import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/security/violation_reporter.dart';
import 'package:pte_app/core/security/violation_retry_coordinator.dart';

class _MockReporter extends Mock implements ViolationReporter {}

class _Canary implements NetworkCanary {
  _Canary(this.stream);

  final Stream<void> stream;

  @override
  Stream<void> get available => stream;

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'student-owned coordinator starts one retry loop and can be disposed',
    () async {
      final reporter = _MockReporter();
      when(() => reporter.retryUnsent()).thenAnswer((_) async {});
      final controller = StreamController<void>.broadcast();
      final timer = Timer(const Duration(hours: 1), () {});
      final coordinator = ViolationRetryCoordinator(
        reporter: reporter,
        canary: _Canary(controller.stream),
        createPeriodicTimer: (_, callback) => timer,
        logger: Logger(),
      );

      coordinator.start();
      coordinator.start();
      expect(coordinator.isStarted, isTrue);
      await coordinator.dispose();

      expect(coordinator.isStarted, isFalse);
      verifyNever(() => reporter.retryUnsent());
      await controller.close();
    },
  );
}
