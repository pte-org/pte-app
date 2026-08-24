import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/scheduling/domain/session_types.dart';

void main() {
  final now = DateTime.utc(2026, 7, 28, 8);

  test('create input trims values and requires a future valid window', () {
    final normalized = CreateSessionInput(
      name: '  Mock exam  ',
      snapshotPublicId: '  snap-1  ',
      opensAt: now.add(const Duration(hours: 1)),
      closesAt: now.add(const Duration(hours: 2)),
    ).normalized(now: now);

    expect(normalized.name, 'Mock exam');
    expect(normalized.snapshotPublicId, 'snap-1');
    expect(
      () => CreateSessionInput(
        name: 'Exam',
        snapshotPublicId: 'snap-1',
        opensAt: now,
        closesAt: now.add(const Duration(hours: 1)),
      ).normalized(now: now),
      throwsA(isA<SchedulingValidationException>()),
    );
  });

  test('composition rejects empty, duplicate, and non-contiguous items', () {
    expect(
      () => SetCompositionInput(items: const []).normalized(),
      throwsA(isA<SchedulingValidationException>()),
    );
    expect(
      () => SetCompositionInput(
        items: const [
          CompositionItemInput(
            taskType: 'READ_ALOUD',
            section: 'SPEAKING',
            orderIndex: 0,
          ),
          CompositionItemInput(
            taskType: 'READ_ALOUD',
            section: 'SPEAKING',
            orderIndex: 1,
          ),
        ],
      ).normalized(),
      throwsA(isA<SchedulingValidationException>()),
    );
  });

  test('session status exposes only the next valid client action', () {
    expect(SessionStatus.scheduled.canOpen, isTrue);
    expect(SessionStatus.scheduled.canClose, isFalse);
    expect(SessionStatus.open.canOpen, isFalse);
    expect(SessionStatus.open.canClose, isTrue);
    expect(SessionStatus.closed.canOpen, isFalse);
    expect(SessionStatus.closed.canClose, isFalse);
  });
}
