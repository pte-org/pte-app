import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/auth/domain/exam_access_policy.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';

void main() {
  test('a student account may take an exam', () {
    expect(
      ExamAccessPolicy.canTakeExam(const JwtClaims(roles: ['STUDENT'])),
      isTrue,
    );
  });

  for (final roles in <List<String>>[
    ['HOST_ADMIN'],
    ['HOST_AUTHOR'],
    ['PROCTOR'],
    ['EXAMINER'],
    ['PLATFORM_ADMIN'],
    ['student'],
    [],
  ]) {
    test('roles $roles may not take an exam', () {
      expect(ExamAccessPolicy.canTakeExam(JwtClaims(roles: roles)), isFalse);
    });
  }
}
