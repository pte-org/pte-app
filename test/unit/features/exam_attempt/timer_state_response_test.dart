import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_state_response.dart';

Map<String, dynamic> _json({
  String phase = 'PREP',
  int currentOrderIndex = 1,
}) {
  return {
    'phase': phase,
    'currentOrderIndex': currentOrderIndex,
    'prepDeadline': '2026-01-01T00:00:30.000Z',
    'responseDeadline': '2026-01-01T00:01:30.000Z',
    'serverNow': '2026-01-01T00:00:10.000Z',
  };
}

void main() {
  test('fromJson parses "PREP" into TimerPhase.prep', () {
    final response = TimerStateResponse.fromJson(_json(phase: 'PREP'));

    expect(response.phase, TimerPhase.prep);
    expect(response.currentOrderIndex, 1);
    expect(response.prepDeadline, DateTime.parse('2026-01-01T00:00:30.000Z'));
    expect(response.responseDeadline, DateTime.parse('2026-01-01T00:01:30.000Z'));
    expect(response.serverNow, DateTime.parse('2026-01-01T00:00:10.000Z'));
  });

  test('fromJson parses "RESPONSE" into TimerPhase.response', () {
    final response = TimerStateResponse.fromJson(_json(phase: 'RESPONSE', currentOrderIndex: 4));

    expect(response.phase, TimerPhase.response);
    expect(response.currentOrderIndex, 4);
  });

  test('fromJson throws FormatException on an unrecognized phase string, never silently defaulting', () {
    expect(() => TimerStateResponse.fromJson(_json(phase: 'BOGUS')), throwsFormatException);
  });
}
