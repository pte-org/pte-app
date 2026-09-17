import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/scheduling/domain/session_types.dart';

void main() {
  final now = DateTime.utc(2026, 7, 28, 8);

  test('create input trims the name and requires a future valid window', () {
    final normalized = CreateSessionInput(
      name: '  Mock exam  ',
      skills: {ExamSkill.speaking},
      opensAt: now.add(const Duration(hours: 1)),
      closesAt: now.add(const Duration(hours: 2)),
    ).normalized(now: now);

    expect(normalized.name, 'Mock exam');
    expect(normalized.skills, {ExamSkill.speaking});
    expect(
      () => CreateSessionInput(
        name: 'Exam',
        skills: {ExamSkill.speaking},
        opensAt: now,
        closesAt: now.add(const Duration(hours: 1)),
      ).normalized(now: now),
      throwsA(isA<SchedulingValidationException>()),
    );
  });

  test('create input rejects empty or more than 4 skills', () {
    expect(
      () => CreateSessionInput(
        name: 'Exam',
        skills: const {},
        opensAt: now.add(const Duration(hours: 1)),
        closesAt: now.add(const Duration(hours: 2)),
      ).normalized(now: now),
      throwsA(isA<SchedulingValidationException>()),
    );
    expect(
      () => CreateSessionInput(
        name: 'Exam',
        skills: ExamSkill.values.toSet(),
        opensAt: now.add(const Duration(hours: 1)),
        closesAt: now.add(const Duration(hours: 2)),
      ).normalized(now: now),
      returnsNormally,
    );
  });

  test('session status exposes only the next valid client action', () {
    expect(SessionStatus.scheduled.canOpen, isTrue);
    expect(SessionStatus.scheduled.canClose, isFalse);
    expect(SessionStatus.scheduled.isScheduled, isTrue);
    expect(SessionStatus.open.canOpen, isFalse);
    expect(SessionStatus.open.canClose, isTrue);
    expect(SessionStatus.open.isScheduled, isFalse);
    expect(SessionStatus.closed.canOpen, isFalse);
    expect(SessionStatus.closed.canClose, isFalse);
    expect(SessionStatus.closed.isScheduled, isFalse);
  });
}
